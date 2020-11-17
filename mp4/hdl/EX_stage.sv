import rv32i_types::*; /* Import types defined in rv32i_types.sv */
/* 
EX stage module. Takes reg values, assigns appropriate MUX signals from control word.
Also outputs ALU and CMP results. 
Execute stage is where the actual computation occurs (Register-Register, Memory Ref, Multi Cycle)
Forwarding from future stages (mem-ex, wb-ex) also integrated using alumux1/2 forwarding selects
Datapath elements - CMP, CMPMux, alumux1, alumux2, ALU
Inputs - reg_a, PC, alumux1_sel, IR from ID/EX buffer, alumux2_sel, reg_b, cmpop, aluop, cmpmuxsel, alumux1/2 forwarding selects and rd_fwd_* fwd results
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
    input logic [31:0] rd_fwd_exmem, // *_fwd* is forwarded from future stage as indicated by suffix
    input logic [31:0] rd_fwd_memwb,
    input fwd::fwd_sel_t alumux1_fwd_sel_exmem, // alumux selects for forwarding logic from 2 future stages
    input fwd::fwd_sel_t alumux2_fwd_sel_exmem,
    input fwd::fwd_sel_t alumux1_fwd_sel_memwb,
    input fwd::fwd_sel_t alumux2_fwd_sel_memwb,
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
logic [31:0] alumux2_out, alumux1_out, cmpmux_out, reg_a_in;

// internal logic for cmp selects for readability
// can use same signals as alumux1/2
//
fwd::fwd_sel_t cmp_rega_fwd_exmem, cmp_rega_fwd_memwb, cmp_regb_fwd_exmem, cmp_regb_fwd_memwb;

assign cmp_rega_fwd_exmem = alumux1_fwd_sel_exmem;
assign cmp_regb_fwd_exmem = alumux2_fwd_sel_exmem;

assign cmp_rega_fwd_memwb = alumux1_fwd_sel_memwb;
assign cmp_regb_fwd_memwb = alumux2_fwd_sel_memwb;

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
        begin
            if((alumux2_fwd_sel_exmem == fwd::use_fwd) & (alumux2_fwd_sel_memwb == fwd::use_fwd))
                // if both true, forward most recent result from exmem
                //
                alumux2_out = rd_fwd_exmem; 
            else if(alumux2_fwd_sel_exmem == fwd::use_fwd) 
                // if one forward true, fwd that stage result
                //
                alumux2_out = rd_fwd_exmem;
            else if(alumux2_fwd_sel_memwb == fwd::use_fwd)
                alumux2_out = rd_fwd_memwb;
            else 
                // default forward reg_b
                //
                alumux2_out = reg_b;
        end
        default:
            alumux2_out = i_imm;
    endcase

    unique case(alumux1_sel)
        alumux::rs1_out:
        begin
            if((alumux1_fwd_sel_exmem == fwd::use_fwd) & (alumux1_fwd_sel_memwb == fwd::use_fwd))
                // if both true, forward most recent result from exmem
                //
                alumux1_out = rd_fwd_exmem; 
            else if(alumux1_fwd_sel_exmem == fwd::use_fwd) 
                // if one forward true, fwd that stage result
                //
                alumux1_out = rd_fwd_exmem;
            else if(alumux1_fwd_sel_memwb == fwd::use_fwd)
                alumux1_out = rd_fwd_memwb;
            else 
                // default forward reg_a
                //
                alumux1_out = reg_a;
        end
        alumux::pc_out:
            alumux1_out = PC_EX;
        default:
            alumux1_out = reg_a;
    endcase

    if ((cmp_rega_fwd_exmem == fwd::use_fwd) & (cmp_rega_fwd_memwb == fwd::use_fwd))
        // if both true, forward most recent result from exmem
        //
        reg_a_in = rd_fwd_exmem;
    else if (cmp_rega_fwd_exmem == fwd::use_fwd)
        // if one forward true, fwd that stage result
        //
        reg_a_in = rd_fwd_exmem;
    else if (cmp_rega_fwd_memwb == fwd::use_fwd)
        reg_a_in = rd_fwd_memwb;
    else
        // else fwd reg_a normally
        reg_a_in = reg_a;

    unique case(cmpmux_sel)
        cmpmux::rs2_out:
        begin
            // if both true, forward most recent result from exmem
            //
            if ((cmp_regb_fwd_exmem == fwd::use_fwd) & (cmp_regb_fwd_memwb == fwd::use_fwd))
                cmpmux_out = rd_fwd_exmem;
            // if one forward true, fwd that stage result
            //
            else if (cmp_regb_fwd_exmem == fwd::use_fwd)
                cmpmux_out = rd_fwd_exmem;
            else if (cmp_regb_fwd_memwb == fwd::use_fwd)
                cmpmux_out = rd_fwd_memwb;
            else
                cmpmux_out = reg_b;
        end
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
    .in1(reg_a_in),
    .in2(cmpmux_out),
    .br_en(br_en)
);

endmodule : EX_stage