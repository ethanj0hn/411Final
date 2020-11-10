import rv32i_types::*;

module RegfileMUX(
    input regfilemux::regfilemux_sel_t select,
    input logic [31:0] in0,
    input logic [31:0] in1,
    input logic [31:0] in2,
    input logic [31:0] in3,
    input logic [31:0] in4,
    input logic [31:0] in5,
    input logic [31:0] in6,
    input logic [31:0] in7,
    input logic [31:0] in8,
    output logic [31:0] out
);

always_comb
begin
    case(select)

        regfilemux::br_en:
        begin
            out = in1;
        end

        regfilemux::u_imm:
        begin
            out = in2;
        end

        regfilemux::lw:
        begin
            out = in3;
        end

        regfilemux::pc_plus4:
        begin
            out = in4;
        end

        regfilemux::lb:
        begin
            out = in5;
        end

        regfilemux::lbu:
        begin
            out = in6;
        end

        regfilemux::lh:
        begin
            out = in7;
        end

        regfilemux::lhu:
        begin
            out = in8;
        end

        default:
            out = in0;
    endcase
end

endmodule : RegfileMUX

module Two_to_one_MUX(
    input logic select,
    input rv32i_word in0,
    input rv32i_word in1,
    output rv32i_word out
);

always_comb
begin
    case(select)
        1'b1:
            out = in1;
        
        1'b0:
            out = in0;

        default:
            out = in0;
    endcase
end

endmodule : Two_to_one_MUX

module alumux2(
    input alumux::alumux2_sel_t alumux2_sel,
    input  logic [31:0] i_imm,
    input  logic [31:0] u_imm,
    input  logic [31:0] b_imm,
    input  logic [31:0] s_imm,
    input  logic [31:0] j_imm, 
    input logic [31:0] rs2_out,
    output  logic [31:0] alumux2_out
);

always_comb
begin
    case(alumux2_sel)
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
            alumux2_out = rs2_out;
        default:
            alumux2_out = i_imm;
    endcase 
end

endmodule : alumux2

module PCMUX(
    input pcmux::pcmux_sel_t select,
    input logic [31:0] pc_plus4,  
    input logic [31:0] alu_out,  
    input logic [31:0] alu_mod2,
    output logic [31:0] pcmux_out  
    );
always_comb
begin
    case(select)
        pcmux::pc_plus4:
            pcmux_out = pc_plus4;
        pcmux::alu_out:
            pcmux_out = alu_out;
        pcmux::alu_mod2:
            pcmux_out = alu_mod2;
        default:
            pcmux_out = pc_plus4;
    endcase
end

endmodule : PCMUX