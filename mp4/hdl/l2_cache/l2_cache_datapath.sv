/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module l2_cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input logic clk,
    input logic reset,
    input logic mem_read,
    input logic mem_write,
    input logic WE0, // Write Enable from CPU
    input logic WE1,
    input logic ld_dirty0, // set dirty, valid, and clear dirty bits
    input logic ld_dirty1,
    input logic ld_valid0,
    input logic ld_valid1,
    input logic clear_dirty0, // clears dirty bit on update state
    input logic clear_dirty1,
    input logic mem_b_sel, // mem byte enable select
    input logic eviction_addr_sel, // which way should be evicted
    input logic mem_addr_sel, // eviction address or CPU address?
    input logic load_lru, // flips lru bit on a read/write, also used to load valid
    input logic [31:0] mem_byte_enable256, // mem_byte enable from bus adapter/CPU
    input logic [31:0] mem_address, // address from CPU
    input logic [s_line - 1:0] pmem_rdata, // data from memory on read
    input logic [255:0] mem_wdata256, // write data from adapter/CPU
    output logic [31:0] pmem_address, // 256 bit aligned address when reading from memory
    output logic [s_line - 1:0] mem_rdata256, // data to data bus->CPU
    output logic [s_line - 1:0] pmem_wdata, // to cacheline adapter for writes to memory
    output logic hit0, // hits on either of the ways
    output logic hit1,
    output logic dirty_eviction, // is eviction going to be dirty?
    output logic LRU // LRU bit to send to control
);

// internal logic for LRU
//
logic LRU_wdata, LRU_in;
always_comb
begin
    if (hit0)
        LRU_in = 1'b1; // if hit on way 0, assign LRU = 1
    else if (hit1)
        LRU_in = 1'b0; // if hit on way 1, assign LRU = 0
    else // only used during update state during eviction, LRU will be the appropriate index's LRU by that time.
        LRU_in = ~LRU;
end

// LRU metadata array
//
l2_array#(3,1) LRU_arr(
    .clk(clk),
    .rst(reset),
    .read(1'b1), // always read
    .load(load_lru),
    .rindex(mem_address[7:5]), // 5 bits offset, then set index
    .windex(mem_address[7:5]),
    .datain(LRU_in), // from above
    .dataout(LRU),
    .dataout_imm() 
);

// internal logic for valid_0
//
logic valid_0_o,valid_0_i;

// for valid bits for way 0, can always put data in as 1'b1, since we never load invalid data except on reset
//
l2_array#(3,1) valid_0(
    .clk(clk),
    .rst(reset),
    .read(1'b1), // always read
    .load(WE0), // load valid whenever we write to cache registers and LRU is way 0
    .rindex(mem_address[7:5]), // 5 bits offset, then set index
    .windex(mem_address[7:5]),
    .datain(1'b1), // always 1 because we never load invalid
    .dataout(valid_0_o), // output from valid 0
    .dataout_imm(valid_0_i) // immediate output from valid0
);

// internal logic for valid_1
//
logic valid_1_o, valid_1_i;

// for valid bits for way 0, can always put data in as 1'b1, since we never load invalid data except on reset
//
l2_array#(3,1) valid_1(
    .clk(clk),
    .rst(reset),
    .read(1'b1),
    .load(WE1), // load valid whenever we write to cache registers & LRU is way 1
    .rindex(mem_address[7:5]), // 5 bits offset, then set index
    .windex(mem_address[7:5]),
    .datain(1'b1), // always 1 because we never load invalid
    .dataout(valid_1_o), // output from valid 0
    .dataout_imm(valid_1_i) // immediate output from valid 1
);

// internal logic for dirty_0
//
logic dirty_0_o, dirty0_in;

// for dirty bits for way 0. 
l2_array#(3,1) dirty_0(
    .clk(clk),
    .rst(reset), 
    .read(1'b1),
    .load(ld_dirty0), // load dirty when set_dirty_bit and it is 
    .rindex(mem_address[7:5]), // 5 bits offset, then set index
    .windex(mem_address[7:5]),
    .datain(!clear_dirty0), // if not clearing, set data in as 1 
    .dataout(dirty_0_o), // output from valid 0
    .dataout_imm()
);

// internal logic for dirty_1
//
logic dirty_1_o, dirty1_in;

// for dirty bits for way 1. 
l2_array#(3,1) dirty_1(
    .clk(clk),
    .rst(reset), 
    .read(1'b1),
    .load(ld_dirty1), // load dirty when set_dirty_bit and it is 
    .rindex(mem_address[7:5]), // 5 bits offset, then set index
    .windex(mem_address[7:5]),
    .datain(!clear_dirty1), // if not clearing, set data in as 1 
    .dataout(dirty_1_o), // output from valid 0
    .dataout_imm()
);

// assign dirty_eviction based on LRU
//
always_comb
begin
    if (!LRU)
        dirty_eviction = dirty_0_o;
    else
        dirty_eviction = dirty_1_o;
end

// internal logic for way0 tags
//
logic hit0_t;
assign hit0 = hit0_t & valid_0_i;
logic [23:0] eviction_addr0;

tag_array tag_way0(
    .clk(clk),
    .reset(reset),
    .load(WE0),
    .addr(mem_address[7:5]),
    .tag_in(mem_address[31:8]),
    .hit(hit0_t),
    .rtag(eviction_addr0)
);

// internal logic for way1 tags
//
logic hit1_t;
assign hit1 = hit1_t & valid_1_i;
logic [23:0] eviction_addr1;

tag_array tag_way1(
    .clk(clk),
    .reset(reset),
    .load(WE1),
    .addr(mem_address[7:5]),
    .tag_in(mem_address[31:8]),
    .hit(hit1_t),
    .rtag(eviction_addr1)
);

// based on eviction addr_sel, construct eviction address
//
logic [31:0] eviction_addr;

// selection of which address to evict if required
//
always_comb
begin
    if (!eviction_addr_sel) // LRU is 0
        eviction_addr = {eviction_addr0,mem_address[7:5],5'b0};
    else
        eviction_addr = {eviction_addr1,mem_address[7:5],5'b0};
end

// selection of which address to assign to
//
always_comb
begin
    if (!mem_addr_sel) // we want address from CPU
        pmem_address = {mem_address[31:5],5'b0};
    else
        pmem_address = eviction_addr;
end

// internal logic for way0 data
//
logic [31:0] mem_b_en0; // mem byte enable
logic [255:0] data0; // output from way0
always_comb
begin
    if (WE0)
    begin
        if (!mem_b_sel) // if writing to way 0 and we want write from bus adapter data, choose bus adapter byte enalble
        begin
            mem_b_en0 = mem_byte_enable256;
        end
        else
            mem_b_en0 = 32'hffffffff; // we are trying to write from memory
    end
    else
        mem_b_en0 = 32'h0; // we are not writing, disable writes
end

// internal logic for way0_mux
//
logic [255:0] way0_din;

write_mux way0_mux(
    .select(mem_write), // read or write from CPU?
    .from_mem(pmem_rdata), // data read from memory
    .from_adapter(mem_wdata256), // write data from CPU
    .mem_byte_enable(mem_byte_enable256), // 32 bit mem_b_enable from CPU
    .data_to_reg(way0_din)
);

l2_data_array #(5,3) way0_d(
    .clk(clk),
    .rst(reset),
    .read(1'b1),
    .write_en(mem_b_en0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(way0_din),
    .dataout(data0)
);


// internal logic for way0 data
//
logic [31:0] mem_b_en1; // mem byte enable
logic [255:0] data1; // output from way1
always_comb
begin
    if (WE1)
    begin
        if (!mem_b_sel) // if writing to way 1 and we want write from bus adapter data, choose bus adapter byte enalble
        begin
            mem_b_en1 = mem_byte_enable256;
        end
        else
            mem_b_en1 = 32'hffffffff; // we are trying to write from memory
    end
    else
        mem_b_en1 = 32'h0; // we are not writing, disable writes
end

// internal logic for way0_mux
//
logic [255:0] way1_din;

write_mux way1_mux(
    .select(mem_write), // read or write from CPU?
    .from_mem(pmem_rdata), // data read from memory
    .from_adapter(mem_wdata256), // write data from CPU
    .mem_byte_enable(mem_byte_enable256), // 32 bit mem_b_enable from CPU
    .data_to_reg(way1_din)
);

l2_data_array #(5,3) way1_d(
    .clk(clk),
    .rst(reset),
    .read(1'b1),
    .write_en(mem_b_en1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(way1_din),
    .dataout(data1)
);

// case statement/MUX to choose output to CPU
//
always_comb
begin
    if (hit0)
        mem_rdata256 = data0;
    else if (hit1)
        mem_rdata256 = data1;
    else
        mem_rdata256 = 256'hX; // on no hits, data is not ready, output X
end

// case statement/MUX to choose output on eviction
//
always_comb
begin
    if (!LRU)
        pmem_wdata = data0;
    else
        pmem_wdata = data1;
end

endmodule : l2_cache_datapath
