import rv32i_types::*;

/*
Module for WB stage. MUX for selecting output to load to regfile
Datapath Elements - regfilemux
Inputs - data value read from memory, signals from IR including u_imm etc, memory address last two bits
Outputs- destination register, regfilemux output
*/
module WB_stage(

    //inputs

    input logic [31:0] data_value, // value read from memory
    input logic [2:0] funct3, 
    input logic br_en, // branch enable to load to register
    input rv32i_word alu_out,
    input logic [31:0] u_imm,
    input rv32i_word pc_out,
    input [1:0] mem_address_last_two_bits,
    input regfilemux::regfilemux_sel_t regfilemux_sel, // regfile mux select

    //outputs to ID_stage
    output logic [4:0] rd_wb, // destination register
    output logic [31:0] regfilemux_out_wb // output of regfilemux
)

load_funct3_t load_funct3;
assign load_funct3 = load_funct3_t'(funct3);
logic [3:0] rmask;

always_comb begin : MUXES
    
    unique case (load_funct3)
        lw: rmask = 4'b1111;
        lh, lhu: 
        begin
            unique case(mem_address_last_two_bits)
                2'b00: rmask = 4'b0011;
                2'b01: rmask = 4'b0011;
                2'b10: rmask = 4'b1100;
                2'b11: rmask = 4'b1100;
                default: rmask = 4'b1111;
            endcase
        end
        lb, lbu:
        begin
            unique case(mem_address_last_two_bits)
                2'b00: rmask = 4'b0001;
                2'b01: rmask = 4'b0010;
                2'b10: rmask = 4'b0100;
                2'b11: rmask = 4'b1000;
                default: rmask = 4'b1111;
            endcase
        end
    endcase

    unique case(regfilemux_sel)
        regfilemux::alu_out: regfilemux_out_wb = alu_out;
        regfilemux::br_en: regfilemux_out_wb = br_en;
        regfilemux::u_imm: regfilemux_out_wb = u_imm;
        regfilemux::lw: regfilemux_out_wb = data_value;
        regfilemux::pc_plus4: regfilemux_out_wb = pc_out + 4;
        regfilemux::lb:
        begin
            unique case(rmask)
                4'b0001: regfilemux_out_wb = { {24{data_value[7]}}, data_value[7:0]};
                4'b0010: regfilemux_out_wb = { {24{data_value[15]}}, data_value[15:8]};
                4'b0100: regfilemux_out_wb = { {24{data_value[23]}}, data_value[23:16]};
                4'b1000: regfilemux_out_wb = { {24{data_value[31]}}, data_value[31:24]};
                default: regfilemux_out_wb = { {24{data_value[23]}}, data_value[7:0]};
            endcase
        end
        regfilemux::lbu:
        begin
            unique case(rmask)
                4'b0001: regfilemux_out_wb =  {24'b0, data_value[7:0]};
                4'b0010: regfilemux_out_wb =  {24'b0, data_value[15:8]};
                4'b0100: regfilemux_out_wb =  {24'b0, data_value[23:16]};
                4'b1000: regfilemux_out_wb =  {24'b0, data_value[31:24]};
                default: regfilemux_out_wb =  {24'b0, data_value[7:0]};
            endcase
        end
        regfilemux::lhu:
        begin
            unique case(rmask)
                4'b0011: regfilemux_out_wb =  {16'b0, data_value[15:0]};
                4'b1100: regfilemux_out_wb =  {16'b0, data_value[31:16]};
                default: regfilemux_out_wb =  {16'b0, data_value[15:0]};
            endcase
        end
        regfilemux::lh:
        begin
            unique case(rmask)
                4'b0011: regfilemux_out_wb = { {16{data_value[15]}}, data_value[15:0]};
                4'b1100: regfilemux_out_wb = { {16{data_value[31]}}, data_value[31:16]};
                default: regfilemux_out_wb = { {16{data_value[15]}}, data_value[15:0]};
            endcase
        end
        

        default: regfilemux_out = 0;
    endcase
end

endmodule : WB_stage