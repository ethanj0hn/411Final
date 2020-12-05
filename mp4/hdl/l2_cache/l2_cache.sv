/* MODIFY. Your cache design. It contains the cache
controller; cache datapath; and bus adapter. */

module l2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 4,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input logic clk,
    input logic rst,

    /* signals to arbiter */
    input logic mem_read, // take in reads and write signals from CPU
    input logic mem_write,
    input logic [255:0] mem_wdata, // take in write data; byte enable; address
    // input logic [3:0] mem_byte_enable,
    input logic [31:0] mem_address,
    output logic [255:0] mem_rdata, // output read data; mem_resp
    output logic mem_resp, 

    /* signals to cacheline adaptor */
    input logic [255:0] pmem_rdata, // data from memory on read
    input logic pmem_resp, // response from physical memory
    output logic pmem_read, // output pmem read and write signals
    output logic pmem_write,
    output logic [255:0] pmem_wdata, //  to cacheline adapter
    output logic [31:0] pmem_address // address to memory
);

logic [31:0] address;// address to cache from bus
assign address = mem_address;

logic reset;
assign reset = rst;

logic WE0; // Write Enable from CPU
logic WE1;
logic ld_dirty0; // set dirty; valid; and clear dirty bits
logic ld_dirty1;
logic ld_valid0;
logic ld_valid1;
logic clear_dirty0; // clears dirty bit on update state
logic clear_dirty1;
logic mem_b_sel; // mem byte enable select
logic eviction_addr_sel; // which way should be evicted
logic mem_addr_sel; // eviction address or CPU address?
logic load_lru; // flips lru bit on a read/write; also used to load valid
logic [31:0] mem_byte_enable256; // mem_byte enable from bus adaptor/CPU
logic [255:0] mem_wdata256; // write data from adaptor
logic [31:0] pmem_addr; // 256 bit aligned address when reading from memory
logic [s_line - 1:0] mem_rdata256; // data to data bus->CPU
logic hit0; // hits on either of the ways
logic hit1;
logic dirty_eviction; // is eviction going to be dirty?
logic LRU; // LRU bit to send to control

assign mem_byte_enable256 = 32'hFFFFFFFF;
assign mem_rdata = mem_rdata256;
assign mem_wdata256 = mem_wdata;

l2_cache_control control
(
    .*
);

l2_cache_datapath datapath
(
    .*
);

// bus_adapter bus_adapter
// (
//     .*
// );

endmodule : l2_cache
