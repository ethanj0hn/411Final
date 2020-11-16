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
    input branchmux::branchmux_sel_t branchmux_sel, // for selecting appropriate inputs, outputs on branch/ju
    input logic [31:0] br_PC, // if branch to be taken, PC + offset
    input logic [31:0] inst_rdata, // read data from cache/memory
    output logic [31:0] inst_addr, // instr read from memory
    output logic inst_read, // read signal for instruction memory
    output logic [31:0] IR_regs_in // in data for IR regs
);

// interal logic for PC
//
logic [31:0] PC_in;

always_comb
begin
    inst_read = 1'b1; // always read

    // PCMUX logic
    //
    unique case (branchmux_sel)
        // if branch taken, load branch PC value, clear instruction currently in IF stage
        //
        branchmux::br_taken:
        begin
            PC_in = br_PC;
            IR_regs_in = 32'h0;
        end
        default:
        begin
            PC_in = inst_addr + 32'h4; // else load PC + 4, load read value from memory
            IR_regs_in = inst_rdata;
        end
    endcase
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
