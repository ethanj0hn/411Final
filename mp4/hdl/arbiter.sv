/* 
ARBITER stage contains two muxes, routing unit and routing mux that interfaces
instruction and data cache with memory 
*/

import rv32i_types::*;


module arbiter(
    input logic clk,
    input logic reset
    
   
    input logic inst_read, // instruction port address, read signal
    input logic [31:0] inst_addr,
    input logic data_read, // data read write signals
    input logic data_write, 
    input logic [31:0] data_addr, 
    input logic [31:0] data_wdata,

    input logic mem_resp_cache,
    input logic [31:0] pmem_rdata,
    input logic pmem_resp,

    output logic [31:0] pmem_addr,
    output logic pmem_read,
    output logic pmem_write,
    output logic pmem_wdata
    
    output logic data_resp, // response from data, instruction memory
    output logic inst_resp,
    output logic [31:0] inst_rdata, // instruction, data read port
    output logic [31:0] data_rdata
);

always_comb
begin : ROUTING MUX
    pmem_wdata = data_wdata;

    if(inst_read)
    begin
        pmem_addr = inst_addr;
        pmem_read = 1'b1;
        pmem_write = 1'b0;
    end
    else begin
        pmem_addr = data_addr;
        pmem_read = data_read;
        pmem_write = data_write;
    end
end

always_comb
begin: ROUTING UNIT
    if(inst_read)
    begin
        inst_resp = pmem_resp;
        inst_rdata = pmem_rdata;
        data_resp = 1'bX;
        data_rdata = 31'bX;
    end
    else
    begin
        data_resp = pmem_resp;
        data_rdata = pmem_rdata;
        inst_resp = 1'bX;
        inst_rdata = 31'bX;
    end
end

endmodule : arbiter