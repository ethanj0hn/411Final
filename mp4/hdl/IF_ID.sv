/* 
IF/ID stage in the pipeline. Includes following datapath elements:
PC, PCMUX IF/ID buffer
IF/ID buffer stores the PC to be passed down the pipeline, Instruction from inst memory.
Inputs - clk, reset, PC + offset for branch, read val from instruction memory.
Outputs - imm vals, instruction, PC value
*/

module IF_ID(

);