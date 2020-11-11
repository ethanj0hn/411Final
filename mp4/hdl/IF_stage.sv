/* 
IF stage in the pipeline. Includes following datapath elements:
PC, PCMUX IF buffer
IF buffer stores the PC to be passed down the pipeline, Instruction from inst memory.
Inputs - clk, reset, PC + offset for branch, read val from instruction memory.
Outputs - imm vals, instruction, PC value, instruction read signal
*/

module IF_stage(
    input logic clk,
    input logic reset,
    input logic br_en, // from ex stage cmp
    input logic br_cw, // from control word on whether there is a branch trying to happen
    input logic j_cw, // jump control word
    input logic [31:0] br_PC, // if branch to be taken, PC + offset
    output logic [31:0] inst_addr, // instr read from memory
    output logic inst_read // read signal for instruction memory
);

// interal logic for PC
//
logic PC_MUX_sel, take_branch;
logic [31:0] PC_in;

// take branch logic high when there is a branch cw in execute stage and br_en high
// PC MUX sel takes alu output when take_branch OR jump control word
//
assign take_branch = br_en & br_cw;
assign PC_MUX_sel = take_branch | take_branch;


always_comb
begin
    inst_read = 1'b1; // always read

    // PCMUX logic
    //
    if(PC_MUX_sel)
        PC_in = br_PC;
    else
        PC_in = inst_addr + 32'h4;
end

// PC in the IF stage that send address to memory
//
pc_register PC(
    .clk(clk),
    .rst(reset),
    .load(1'b1), // for now, we are always loading every cycle change when stalling pipeline required
    .in(PC_in),
    .out(inst_addr)
);

endmodule : IF_stage
