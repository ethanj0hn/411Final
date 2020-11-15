/* 
MEM stage in the pipeline. Includes following datapath elements:
Data Memory
Memory Accesses done in this stage, Data Memory (MDR) accessed
Inputs - clk, reset, fucnt3, rs2, alu_out
Outputs - last two bits of mem_address, mem_address, mem_byte_enable
*/

import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module MEM_stage(
    input clk,
    input rst,

    // from current IR
    input [2:0] funct3_mem,

    // from exec buffers
    input [31:0] rs2_out_buffered,
    input [31:0] alu_buffered, // calculated address

    // to wb buffer
    output logic [1:0] mem_address_last_two_bits,

    // interfacing cache / memory
    output logic [31:0] mem_wdata,
    output logic [31:0] mem_address,
    output logic [3:0] mem_byte_enable
);

// local conversion of alu_buffered
assign mem_address = {alu_buffered[31:2], 2'b00};
assign mem_address_last_two_bits = alu_buffered[1:0];

// muxes
always_comb
begin
    case (store_funct3_t'(funct3_mem))
        sw: mem_wdata = rs2_out_buffered;
        sh: 
        begin
            case (mem_address_last_two_bits)
                2'b00, 2'b01 : mem_wdata = {16'b0, rs2_out_buffered[15:0]};
                2'b10, 2'b11 : mem_wdata = {rs2_out_buffered[15:0], 16'b0};
                default: mem_wdata = rs2_out_buffered;
            endcase
        end
        sb:
        begin
            case (mem_address_last_two_bits)
                2'b00 : mem_wdata = {24'b0, rs2_out_buffered[7:0]};
                2'b01 : mem_wdata = {16'b0, rs2_out_buffered[7:0], 8'b0};
                2'b10 : mem_wdata = {8'b0, rs2_out_buffered[7:0], 16'b0};
                2'b11 : mem_wdata = {rs2_out_buffered[7:0], 24'b0};
                default : mem_wdata = rs2_out_buffered;
            endcase
        end
        default: mem_wdata = rs2_out_buffered;
    endcase

    case (store_funct3_t'(funct3_mem))
        sw: mem_byte_enable = 4'b1111;
        sh:
        begin
            unique case(mem_address_last_two_bits)
                default: mem_byte_enable = 4'b1111;
                2'b00, 2'b01: mem_byte_enable = 4'b0011;
                2'b10, 2'b11: mem_byte_enable = 4'b1100;
            endcase
        end
        sb:
        begin
            unique case(mem_address_last_two_bits)
                default: mem_byte_enable = 4'b1111;
                2'b00: mem_byte_enable = 4'b0001;
                2'b01: mem_byte_enable = 4'b0010;
                2'b10: mem_byte_enable = 4'b0100;
                2'b11: mem_byte_enable = 4'b1000;
            endcase
        end
        default: mem_byte_enable = 4'b1111;
    endcase
end

endmodule : MEM_stage