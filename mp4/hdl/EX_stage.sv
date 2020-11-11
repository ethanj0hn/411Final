import rv32i_types::*; /* Import types defined in rv32i_types.sv */
/* 
EX stage module. Takes reg values, assigns appropriate MUX signals from control word.
Also outputs ALU and CMP results. 
Datapath elements - CMP, CMPMux, alumux1, alumux2, ALU
Inputs - reg_a, PC, alumux1_sel, IR from ID/EX buffer, alumux2_sel, reg_b, cmpop, aluop, cmpmuxsel
Outputs- ALU output, br_en
*/
module EX_stage(
    input logic [31:0] reg_a, // all inputs, outputs as above
    input logic [31:0] PC_EX,
    input alumux::alumux1_sel_t alumux1_sel,
    input logic [31:0] IR_EX,
    input logic [31:0] reg_b,
    input alumux::alumux2_sel_t alumux2_sel,
    input branch_funct3_t cmpop, 
    input alu_ops aluop,
    input cmpmux::cmpmux_sel_t cmpmux_sel,
    output logic [31:0] ALU_out,
    output logic br_en
);
// Internal logic for operands
//
logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;

// assignments for immediate operands from input IR
//
assign i_imm = {{21{IR_EX[31]}}, IR_EX[30:20]};
assign s_imm = {{21{IR_EX[31]}}, IR_EX[30:25], IR_EX[11:7]};
assign b_imm = {{20{IR_EX[31]}}, IR_EX[7], IR_EX[30:25], IR_EX[11:8], 1'b0};
assign u_imm = {IR_EX[31:12], 12'h000};
assign j_imm = {{12{IR_EX[31]}}, IR_EX[19:12], IR_EX[20], IR_EX[30:21], 1'b0};

// MUXes and internal logic for muxes
//
logic [31:0] alumux2_out, alumux1_out, cmpmux_out;

always_comb
begin
    unique case(alumux2_sel)
        alumux::i_imm:
            alumux2_out = i_imm;
        alumux::u_imm:
            alumux2_out = u_imm;
        alumux::b_imm:
            alumux2_out = b_imm;
        alumux::s_imm:
            alumux2_out = s_imm;
        alumux::j_imm:
            alumux2_out = j_imm;
        alumux::rs2_out:
            alumux2_out = reg_b;
        default:
            alumux2_out = i_imm;
    endcase

    unique case(alumux1_sel)
        alumux::rs1_out:
            alumux1_out = reg_a;
        alumux::pc_out:
            alumux1_out = PC_EX;
        default:
            alumux1_out = reg_a;
    endcase

    unique case(cmpmux_sel)
        cmpmux::rs2_out:
            cmpmux_out = reg_b;
        cmpmux::i_imm:
            cmpmux_out = i_imm;
        default:
            cmpmux_out = reg_b;
    endcase
end

alu ALU(
    .aluop(aluop),
    .a(alumux1_out), 
    .b(alumux2_out),
    .f(ALU_out)
);

cmp CMP(
    .br_func(cmpop),
    .in1(reg_a),
    .in2(cmpmux_out),
    .br_en(br_en)
);

endmodule : EX_stage