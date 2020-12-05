/* 
arbiter contains an if else block that connects
the appropiate icache and dcache signals to l2 cache
and implements the prefetcher (TODO)
*/


module arbiter(
    input logic clk,
    input logic reset,
    
    input logic i_pmem_read,
    input logic i_pmem_write,
    input logic [31:0] i_pmem_address,
    input logic [255:0] i_pmem_wdata,
    input logic d_pmem_read,
    input logic d_pmem_write,
    input logic [31:0] d_pmem_address,
    input logic [255:0] d_pmem_wdata,
    input logic [255:0] ab_pmem_rdata,
    input logic ab_pmem_resp,

    output logic ab_pmem_read,
    output logic ab_pmem_write,
    output logic [31:0] ab_pmem_address,
    output logic [255:0] ab_pmem_wdata,
    output logic [255:0] i_pmem_rdata,
    output logic i_pmem_resp,
    output logic [255:0] d_pmem_rdata,
    output logic d_pmem_resp,

    input logic [31:0] inst_addr,
    input logic inst_present,
    output logic [31:0] prefetch_data_addr,
    input logic data_present
);

/* State Enumeration */
enum int unsigned
{
    ready,
    prefetch_instruction,
    prefetch_data
} state, next_state;

// stride prefetcher variables
logic load_data;
logic load_inst;
logic [31:0] prev_in;
logic [31:0] prev_out;
logic [31:0] data_in;
logic [31:0] data_out;
logic [31:0] inst_in;
logic [31:0] inst_out;

assign prefetch_data_addr = data_out;

always_comb
begin
    // default assignments
    next_state = state;
    ab_pmem_read = 1'b0;
    ab_pmem_write = 1'b0;
    ab_pmem_address = 32'b0;
    ab_pmem_wdata = 256'b0;
    i_pmem_rdata = 256'b0;
    i_pmem_resp = 1'b0;
    d_pmem_rdata = 256'b0;
    d_pmem_resp = 1'b0;
    
    // stride prefetcher default assignments
    load_data = 1'b0;
    load_inst = 1'b0;
    prev_in = 32'b0;
    data_in = 32'b0;
    inst_in = 32'b0;

    case (state)
        ready: begin
            if (i_pmem_read | d_pmem_read | d_pmem_write) begin

                
                if (d_pmem_read | d_pmem_write) begin

                    // update predicted data access by stride and save previous

                    load_data = 1'b1;
                    
                    if (prev_out != 32'b0)
                        data_in = d_pmem_address + d_pmem_address - prev_out;
                    prev_in = d_pmem_address;

                    // inputs
                    ab_pmem_read = d_pmem_read;
                    ab_pmem_write = d_pmem_write;
                    ab_pmem_address = d_pmem_address;
                    ab_pmem_wdata = d_pmem_wdata;

                    // outputs to dcache
                    d_pmem_rdata = ab_pmem_rdata;
                    d_pmem_resp = ab_pmem_resp;

                    // outputs to icache
                    i_pmem_rdata = 256'b0;
                    i_pmem_resp = 1'b0;
                end
                else begin

                    // inputs
                    ab_pmem_read = i_pmem_read;
                    ab_pmem_write = i_pmem_write;
                    ab_pmem_address = i_pmem_address;
                    ab_pmem_wdata = i_pmem_wdata;
                    
                    // outputs to icache
                    i_pmem_rdata = ab_pmem_rdata;
                    i_pmem_resp = ab_pmem_resp;
                    
                    // outputs to dcache
                    d_pmem_rdata = 256'b0;
                    d_pmem_resp = 1'b0;
                end
            end
            else if ((prefetch_data_addr != 32'b0) & (~data_present))
                next_state = prefetch_data;
            else if (~inst_present) begin
                next_state = prefetch_instruction;
                load_inst = 1'b1;
                inst_in = inst_addr;
            end
            
        end
        prefetch_instruction: begin
            if (ab_pmem_resp)
                next_state = ready;
            
            ab_pmem_read = 1'b1;
            ab_pmem_address = inst_out + 32'h00000020;
        end
        prefetch_data: begin
            if (ab_pmem_resp)
                next_state = ready;
            
            ab_pmem_read = 1'b1;
            ab_pmem_address = prefetch_data_addr;
        end
        default: ;
    endcase
    
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
    state <= next_state;
end

// register to store previous data access
register #(32) prev_address(
    .clk(clk),
    .rst(reset),
    .load(load_data),
    .in(prev_in),
    .out(prev_out)
);

// register to store data to prefetch
register #(32) address_to_prefetch(
    .clk(clk),
    .rst(reset),
    .load(load_data),
    .in(data_in),
    .out(data_out)
);

// register to store inst_addr
register #(32) inst_addr_store(
    .clk(clk),
    .rst(reset),
    .load(load_inst),
    .in(inst_in),
    .out(inst_out)
);

endmodule : arbiter