/* 
arbiter contains an if else block that connects
the appropiate icache and dcache signals to l2 cache
and implements the prefetcher (TODO)
*/


module arbiter(
    input logic clk,
    
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
    input logic [31:0] inst_addr,
    input logic inst_present,

    output logic ab_pmem_read,
    output logic ab_pmem_write,
    output logic [31:0] ab_pmem_address,
    output logic [255:0] ab_pmem_wdata,
    output logic [255:0] i_pmem_rdata,
    output logic i_pmem_resp,
    output logic [255:0] d_pmem_rdata,
    output logic d_pmem_resp
);

/* State Enumeration */
enum int unsigned
{
    ready,
    prefetch
} state, next_state;

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

    case (state)
        ready: begin
            if (i_pmem_read | d_pmem_read | d_pmem_write) begin

                if (i_pmem_read) begin

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
                else begin

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
            end
            else if (~inst_present)
                next_state = prefetch;
        end
        prefetch: begin
            if (ab_pmem_resp)
                next_state = ready;
            
            ab_pmem_read = 1'b1;
            ab_pmem_address = inst_addr + 32'h00000020;
        end
        default: ;
    endcase
    
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
    state <= next_state;
end

endmodule : arbiter