import rv32i_types::*;

module WB_stage(

    //inputs

    input 
    input logic [2:0] funct3, 

    input [1:0] mem_address_last_two_bits,
    input rv32i_control_word ctrl,

    //outputs to ID_stage
    output logic [4:0] rd_wb,
    output logic load_regfile_wb,
    output logic [31:0] regfilemux_out_wb
)


always_comb begin : MUXES

    unique case(regfilemux_sel)
        regfilemux::alu_out: regfilemux_out_wb = alu_out;
        regfilemux::br_en: regfilemux_out_wb = br_en;
        regfilemux::u_imm: regfilemux_out_wb = u_imm;
        regfilemux::lw: regfilemux_out_wb = mdrreg_out;
        regfilemux::pc_plus4: regfilemux_out_wb = pc_out + 4;
        regfilemux::lb:
        begin
            unique case(rmask)
                4'b0001: regfilemux_out_wb = { {24{mdrreg_out[7]}}, mdrreg_out[7:0]};
                4'b0010: regfilemux_out_wb = { {24{mdrreg_out[15]}}, mdrreg_out[15:8]};
                4'b0100: regfilemux_out_wb = { {24{mdrreg_out[23]}}, mdrreg_out[23:16]};
                4'b1000: regfilemux_out_wb = { {24{mdrreg_out[31]}}, mdrreg_out[31:24]};
                default: regfilemux_out_wb = { {24{mdrreg_out[23]}}, mdrreg_out[7:0]};
            endcase
        end
        regfilemux::lbu:
        begin
            unique case(rmask)
                4'b0001: regfilemux_out_wb =  {24'b0, mdrreg_out[7:0]};
                4'b0010: regfilemux_out_wb =  {24'b0, mdrreg_out[15:8]};
                4'b0100: regfilemux_out_wb =  {24'b0, mdrreg_out[23:16]};
                4'b1000: regfilemux_out_wb =  {24'b0, mdrreg_out[31:24]};
                default: regfilemux_out_wb =  {24'b0, mdrreg_out[7:0]};
            endcase
        end
        regfilemux::lhu:
        begin
            unique case(rmask)
                4'b0011: regfilemux_out_wb =  {16'b0, mdrreg_out[15:0]};
                4'b1100: regfilemux_out_wb =  {16'b0, mdrreg_out[31:16]};
                default: regfilemux_out_wb =  {16'b0, mdrreg_out[15:0]};
            endcase
        end
        regfilemux::lh:
        begin
            unique case(rmask)
                4'b0011: regfilemux_out_wb = { {16{mdrreg_out[15]}}, mdrreg_out[15:0]};
                4'b1100: regfilemux_out_wb = { {16{mdrreg_out[31]}}, mdrreg_out[31:16]};
                default: regfilemux_out_wb = { {16{mdrreg_out[15]}}, mdrreg_out[15:0]};
            endcase
        end
        

        default: regfilemux_out = 0;
    endcase
end