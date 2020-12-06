/*
Basic local branch predictor. Looks up PC, outputs prediction based on state.
*/
import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module local_branch_predictor(
    input logic clk,
    input logic reset,
    input logic [31:0] PC,
    input logic result, // for updating state
    input logic is_br,
    input logic pipeline_en,
    output prediction_choice prediction
);

logic [31:0] PC_arr[4]; // PC_arr for existing local addresses
logic [31:0] PC_shift_reg[2]; // storing old PC values
logic [31:0] PC_arr_in, PC_sr_in; // PC_arr in
logic hit; // is our PC in the current array?
logic load[4]; // for deciding which state machine to update
logic [1:0] next_idx; // next write idx in PC_arr
prediction_choice predictions[4]; // if match in PC, predict from that state machine

always_comb
begin
    prediction = no_take; // default predict don't take branch
    hit = 1'b0;
    PC_arr_in = PC; // if we need to write to PC arr
    PC_sr_in = PC; // shift reg input
    for(int i = 0;i < 4;i = i + 1)
    begin
        if (PC_arr[i] == PC) // search for hit, if there is a hit output predictions[i], note that there is a hit
        begin
            prediction = predictions[i];
            hit = 1'b1;
        end
    end
    for(int i=0; i< 4; i= i + 1)
        load[i] = ( (PC_shift_reg[1] == PC_arr[i]) & is_br & pipeline_en);
end

always_ff @(posedge clk)
begin
    if (reset)
    begin
        next_idx <= 2'b0; // reset next write index to 0
        PC_shift_reg[0] <= 32'h0;
        PC_shift_reg[1] <= 32'h0;
        for(int i = 0;i < 4;i = i + 1) // reset data for PC vals
            PC_arr[i] <= 32'h0;
    end
    else if(!hit & is_br) // if no hit and is a branch, load new PC val, change next_idx
    begin
        PC_arr[next_idx] <= PC_arr_in;
        next_idx <= next_idx + 2'b01;

        PC_shift_reg[0] <= PC_sr_in; // always shift in PC in shift reg
        PC_shift_reg[1] <= PC_shift_reg[0];
    end
    else // else hold value
    begin
        next_idx <= next_idx; // hold next_idx if no write
        PC_shift_reg[0] <= PC_sr_in; // always shift in PC in shift reg
        PC_shift_reg[1] <= PC_shift_reg[0];
        for(int i = 0;i < 4;i = i + 1) // hold data for PC arr
            PC_arr[i] <= PC_arr[i];
    end
end

predictor_state_machine P0(
    .clk(clk),
    .reset(reset),
    .correct_br(result),
    .load(load[0]),
    .prediction(predictions[0])
);

predictor_state_machine P1(
    .clk(clk),
    .reset(reset),
    .correct_br(result),
    .load(load[1]),
    .prediction(predictions[1])
);

predictor_state_machine P2(
    .clk(clk),
    .reset(reset),
    .correct_br(result),
    .load(load[2]),
    .prediction(predictions[2])
);

predictor_state_machine P3(
    .clk(clk),
    .reset(reset),
    .correct_br(result),
    .load(load[3]),
    .prediction(predictions[3])
);


endmodule : local_branch_predictor