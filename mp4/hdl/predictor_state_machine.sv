/* 
Predictor state machine
*/
import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module predictor_state_machine(
    input logic clk,
    input logic reset,
    input logic correct_br,
    input logic load,
    output prediction_choice prediction
);

predictor_state state, next_state;

always_comb
begin
    next_state = state;
    case (state)
        strongly_not_taken: begin
            if (correct_br)
                next_state = strongly_not_taken;
            else
                next_state = not_taken;
        end
        not_taken: begin
            if (correct_br)
                next_state = strongly_not_taken;
            else
                next_state = taken;
        end
        taken: begin
            if (correct_br)
                next_state = strongly_taken;
            else
                next_state = not_taken;
        end
        strongly_taken: begin
            if (correct_br)
                next_state = strongly_taken;
            else
                next_state = taken;
        end
        default: ;
    endcase
end

always_comb
begin
    unique case (state)
        taken, strongly_taken:
            prediction = take;
        default: 
            prediction = no_take;
    endcase
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
    if (reset)
        state <= not_taken;
    else if (load)
	    state <= next_state;
    else
        state <= state;
end

endmodule : predictor_state_machine
