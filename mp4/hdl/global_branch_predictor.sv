module global_branch_predictor (
  input clk,
  input logic write_en,
  input logic [31:0] pc_value,
  input logic branch_taken,
  output logic take_branch
);


logic [31:0] counter [16] = '{default: '0};
logic [19:0] tag [16] = '{default: '0};

logic [3:0] pc_index;
logic [15:0] pc_tag;


logic [31:0] new_count;

assign pc_index = pc_value[11:8];
assign pc_tag = pc_value[31:12];

// branch is taken if there were greater or equal branches than non branches for that set of pc values
assign take_branch = $signed(counter[pc_index]) >= $signed(32'h00000000);

always_comb
begin
    if (tag[pc_index] == pc_tag) begin
        // if tag matches update value
        if (branch_taken) begin
            // avoiding overflow
            if (counter[pc_index] == 32'h7FFFFFFF)
                new_count = 32'h7FFFFFFF;
            else
                new_count = counter[pc_index] + 32'h00000001;
        end
        else begin
            // avoiding overflow
            if (counter[pc_index] == 32'h800000000)
                new_count = 32'h800000000;
            else
                new_count = counter[pc_index] + 32'hFFFFFFFF;
        end
    end
    else begin
        // if tag doesn't match then write new values
        if (branch_taken)
            new_count <= 32'h00000001;
        else
            new_count <= 32'hFFFFFFFF;
    end
end

always_ff @(posedge clk) begin
    if (write_en) begin
        tag[pc_index] <= pc_tag;
        counter[pc_index] <= new_count;
    end
end

endmodule : global_branch_predictor
