import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module ID_stage(
    input clk,
    input rst,

    // inputs coming from fetch
    input [2:0] funct3_if,
    input [6:0] funct7_if,
    input rv32i_opcode opcode_if,
    input [4:0] rs1_if,
    input [4:0] rs2_if,

    // outputs to execute
    output logic [31:0] rs1_out_ex,
    output logic [31:0] rs2_out_ex,

    // inputs from writeback
    input [4:0] rd_wb,
    input load_regfile_wb,
    input [31:0] regfilemux_out_wb,

    // control word output
    output rv32i_control_word ctrl

);

always_comb
begin
    ctrl.opcode = opcode_if;

    // default assignments
    ctrl.load_regfile = 1'b0;
    ctrl.load_data_address = 1'b0;
    ctrl.load_data_value = 1'b0;
    ctrl.data_read = 1'b0;
    ctrl.data_write = 1'b0;
    ctrl.load_data_out = 1'b0;
    ctrl.aluop = alu_ops'(funct3_if);
    ctrl.cmpop = branch_funct3_t'(funct3_if);
    ctrl.alumux1_sel = alumux::rs1_out;
    ctrl.alumux2_sel = alumux::i_imm;
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.cmpmux_sel = cmpmux::rs2_out;

    case (opcode_if)
        op_imm: begin
            ctrl.load_regfile = 1'b1;
            case (arith_funct3_t'(funct3_if))
                slt: begin
                    ctrl.cmpop = blt;
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end
                sltu: begin
                    ctrl.cmpop = bltu;
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end
                sr: begin
                    if (funct7_if != 7'b0)
                        ctrl.aluop = alu_sra;
                end
                default: ;
            endcase
        end
        op_reg: begin
            ctrl.load_regfile = 1'b1;
            case (arith_funct3_t'(funct3_if))
                slt: begin
                    ctrl.cmpop = blt;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end
                sltu: begin
                    ctrl.cmpop = bltu;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end
                sr: begin
                    ctrl.alumux2_sel = alumux::rs2_out;
                    if (funct7_if != 7'b0)
                        ctrl.aluop = alu_sra;
                end
                add: begin
                    ctrl.alumux2_sel = alumux::rs2_out;
                    if (funct7_if != 7'b0)
                        ctrl.aluop = alu_sub;
                end
                default:
                    ctrl.alumux2_sel = alumux::rs2_out;
            endcase
        end
        op_lui: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::u_imm;
        end
        op_auipc: begin
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::u_imm;
            ctrl.load_regfile = 1'b1;
        end
        op_jal: begin
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::j_imm;
            ctrl.aluop = alu_add;
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
        end
        op_jalr: begin
            ctrl.aluop = alu_add;
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
        end
        op_br: begin
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::b_imm;
            ctrl.aluop = alu_add;
        end
        op_load: begin
            ctrl.aluop = alu_add;
            ctrl.load_data_address = 1'b1;
            ctrl.load_data_value = 1'b1;
            ctrl.data_read = 1'b1;
            ctrl.load_regfile = 1'b1;
            case (load_funct3_t'(funct3_if))
                lw : ctrl.regfilemux_sel = regfilemux::lw;
                lb: ctrl.regfilemux_sel = regfilemux::lb;
                lbu: ctrl.regfilemux_sel = regfilemux::lbu;
                lh: ctrl.regfilemux_sel = regfilemux::lh;
                lhu: ctrl.regfilemux_sel = regfilemux::lhu;
                default: ;
            endcase
        end
        op_store: begin
            ctrl.aluop = alu_add;
            ctrl.alumux2_sel = alumux::s_imm;
            ctrl.load_data_address = 1'b1;
            ctrl.load_data_out = 1'b1;
            ctrl.data_write = 1'b1;
        end

        default: ctrl = 0;
    endcase
end


regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(load_regfile_wb),
    .in(regfilemux_out_wb),
    .src_a(rs1_if),
    .src_b(rs2_if),
    .dest(rd_wb),
    .reg_a(rs1_out_ex),
    .reg_b(rs2_out_ex)
);

endmodule : ID_stage