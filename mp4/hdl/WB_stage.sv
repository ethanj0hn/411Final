import rv32i_types::*;

module WB_stage(

    //inputs

    input [31:0] alu_out, //from EX stage
    input [31:0] read_data, //from Data Memory
    input alu_read_sel,

    
    input rv32i_control_word ctrl,


    output logic wb_pc,
    //outputs to ID_stage
    output logic [4:0] rd_wb,
    output logic load_regfile_wb,
    output logic [31:0] regfilemux_out_wb
)

logic [31:0] mux_out;

always_comb begin : MUXES

    unique case(alu_read_sel):
        1'b0: mux_out = alu_out;
        1'b1: mux_out = read_data;
        default: mux_out = alu_out;
    endcase

    unique case(ctrl.regfilemux_sel):
        regfilemux::alu_out: regfilemux_out_wb = mux_out;
        regfilemux::br_en: regfilemux_out_wb = br_en;
        regfilemux::u_imm: regfilemux_out_wb = u_imm;
        default: regfilemux_out_wb = mux_out;
    endcase

end