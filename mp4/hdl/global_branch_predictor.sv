
import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module global_branch_predictor (
  input clk,
  input logic write_en,
  input logic [31:0] curr_pc_value,
  input logic [31:0] prev_pc_value,
  input prediction_choice branch_taken,
  output prediction_choice take_branch
);


logic [31:0] counter [16] = '{default: '0};
logic [19:0] tag [16] = '{default: '0};

logic [3:0] curr_pc_index;
logic [3:0] prev_pc_index;
logic [15:0] prev_pc_tag;


logic [31:0] new_count;

assign curr_pc_index = curr_pc_value[11:8];
assign prev_pc_index = prev_pc_value[11:8];
assign prev_pc_tag = prev_pc_value[31:12];

// branch is taken if there were greater or equal branches than non branches for that set of pc values
assign take_branch = prediction_choice'($signed(counter[curr_pc_index]) > $signed(32'h00000000));

always_comb
begin
    if (tag[prev_pc_index] == prev_pc_tag) begin
        // if tag matches update value
        if (branch_taken == take) begin
            // avoiding overflow
            if (counter[prev_pc_index] == 32'h7FFFFFFF)
                new_count = 32'h7FFFFFFF;
            else
                new_count = counter[prev_pc_index] + 32'h00000001;
        end
        else begin
            // avoiding overflow
            if (counter[prev_pc_index] == 32'h80000000)
                new_count = 32'h80000000;
            else
                new_count = counter[prev_pc_index] + 32'hFFFFFFFF;
        end
    end
    else begin
        // if tag doesn't match then write new values
        if (branch_taken == take)
            new_count <= 32'h00000001;
        else
            new_count <= 32'hFFFFFFFF;
    end
end

always_ff @(posedge clk) begin
    if (write_en) begin
        tag[prev_pc_index] <= prev_pc_tag;
        counter[prev_pc_index] <= new_count;
    end
end

endmodule : global_branch_predictor
