import rv32i_types::*;

module cmp(
    input branch_funct3_t br_func,
    input rv32i_word in1,
    input rv32i_word in2,
    output logic br_en
);

always_comb
begin
    unique case (br_func)
        beq  : br_en = (in1 == in2);
        bne  : br_en = (in1 != in2);
        blt  : br_en = ($signed(in1) < $signed(in2));
        bge  : br_en = ($signed(in1) >= $signed(in2));
        bltu : br_en = (in1 < in2);
        bgeu : br_en = (in1 >= in2);
        default: br_en = 0;
    endcase
end

endmodule : cmp