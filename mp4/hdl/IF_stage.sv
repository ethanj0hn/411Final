/* 
IF stage in the pipeline. Includes following datapath elements:
PC, PCMUX IF buffer
IF buffer stores the PC to be passed down the pipeline, Instruction from inst memory.
Inputs - clk, reset, PC + offset for branch, read val from instruction memory.
Outputs - imm vals, instruction, PC value, instruction read signal
*/

import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module IF_stage(
    input logic clk,
    input logic reset,
    input branchmux::branchmux_sel_t branchmux_sel, // for selecting appropriate inputs, outputs on branch/ju
    input logic pipeline_en, // controls pipeline flow
    input logic [31:0] br_PC, // if branch to be taken, PC + offset
    input logic [31:0] non_br_PC,
    input logic correct_br,
    input logic [31:0] ir_id_ex, // buffered IR
    input logic [31:0] inst_rdata, // read data from cache/memory
    output logic [31:0] inst_addr, // instr read from memory
    output logic inst_read, // read signal for instruction memory
    output logic [31:0] IR_regs_in, // in data for IR regs
    output logic predicted_branch
);

// interal logic for PC
//
logic [31:0] PC_in;

logic [31:0] b_imm;
logic [31:0] j_imm;

assign b_imm = {{20{inst_rdata[31]}}, inst_rdata[7], inst_rdata[30:25], inst_rdata[11:8], 1'b0};
assign j_imm = {{12{inst_rdata[31]}}, inst_rdata[19:12], inst_rdata[20], inst_rdata[30:21], 1'b0};

/* local predictor */
prediction_choice local_prediction;
logic local_buffer;
logic local_out;

local_branch_predictor lbp(
    .clk(clk),
    .reset(reset),
    .PC(inst_addr),
    .result((branchmux_sel == branchmux::br_not_taken)), // for updating state 1 correct prediction and 0 for incorrect
    .is_br((rv32i_opcode'(inst_rdata[6:0]) == op_br)),
    .is_br_idex((rv32i_opcode'(ir_id_ex[6:0]) == op_br)),
    .pipeline_en(pipeline_en),
    .prediction(local_prediction)
);
register #(1) local_buff_1(
    .clk(clk),
    .rst(reset),
    .load(pipeline_en),
    .in(local_prediction == take),
    .out(local_buffer)
);
register #(1) local_buff_2(
    .clk(clk),
    .rst(reset),
    .load(pipeline_en),
    .in(local_buffer),
    .out(local_out)
);

/* global branch predictor */
prediction_choice global_prediction;
logic global_buffer;
logic global_out;

global_branch_predictor gbp(
    .clk(clk),
    .write_en((rv32i_opcode'(ir_id_ex[6:0]) == op_br) & pipeline_en),
    .curr_pc_value(inst_addr),
    .prev_pc_value(non_br_PC),
    .branch_taken(prediction_choice'(correct_br)),
    .take_branch(global_prediction)
);
register #(1) global_buff_1(
    .clk(clk),
    .rst(reset),
    .load(pipeline_en),
    .in(global_prediction == take),
    .out(global_buffer)
);
register #(1) global_buff_2(
    .clk(clk),
    .rst(reset),
    .load(pipeline_en),
    .in(global_buffer),
    .out(global_out)
);


/* tournament predictor */
logic local_correct;
logic global_correct;

assign local_correct = (local_out == correct_br) & (global_out != correct_br);
assign global_correct = (global_out == correct_br) & (local_out != correct_br);

enum int unsigned
{
    strongly_local,
    _local,
    _global,
    strongly_global
} state, next_state;

always_comb
begin
    next_state = state;
    if (rv32i_opcode'(ir_id_ex[6:0]) == op_br) begin
        case (state)
            strongly_local: begin
                if (local_correct)
                    next_state = strongly_local;
                else if (global_correct)
                    next_state = _local;
            end
            _local: begin
                if (local_correct)
                    next_state = strongly_local;
                else if (global_correct)
                    next_state = _global;
            end
            _global: begin
                if (local_correct)
                    next_state = _local;
                else if (global_correct)
                    next_state = strongly_global;
            end
            strongly_global: begin
                if (local_correct)
                    next_state = _global;
                else if (global_correct)
                    next_state = strongly_global;
            end
            default: ;
        endcase
    end
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
    if (pipeline_en)
        state <= next_state;
end


// prediction and correction logic
prediction_choice prediction;
always_comb
begin
    inst_read = 1'b1; // always read
    predicted_branch = 1'b0;
    
    // choose which predictor to use depending on state machine
    if ((state == strongly_global) | (state == _global))
        prediction = global_prediction;
    else
        prediction = local_prediction;

    // PCMUX logic
    //
    unique case (branchmux_sel)
        // if branch taken, load branch PC value, clear instruction currently in IF stage
        //
        branchmux::br_taken:
        begin
            if (rv32i_opcode'(ir_id_ex[6:0]) == op_jalr)
                PC_in = br_PC;
            else if (correct_br)
                PC_in = br_PC;
            else
                PC_in = non_br_PC + 32'h4;
            IR_regs_in = 32'h0;
        end
        default:
        begin
            if (rv32i_opcode'(inst_rdata[6:0]) == op_br) begin
                if (prediction == take) begin // (state == strongly_taken) | (state == taken) - old
                    PC_in = inst_addr + b_imm;
                    predicted_branch = 1'b1;
                end
                else begin
                    PC_in = inst_addr + 32'h4;
                    predicted_branch = 1'b0;
                end
            end
            else if (rv32i_opcode'(inst_rdata[6:0]) == op_jal) begin
                PC_in = inst_addr + j_imm;
            end
            else begin
                PC_in = inst_addr + 32'h4; // else load PC + 4, load read value from memory
            end
            IR_regs_in = inst_rdata;
        end
    endcase
end

// PC in the IF stage that send address to memory
//
pc_register PC(
    .clk(clk),
    .rst(reset),
    .load(pipeline_en), // for now, we are always loading every cycle change when stalling pipeline required
    .in(PC_in),
    .out(inst_addr)
);

endmodule : IF_stage
