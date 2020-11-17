
module regfile
(
    input clk,
    input rst,
    input load,
    input [31:0] in,
    input [4:0] src_a, src_b, dest,
    output logic [31:0] reg_a, reg_b
);

//logic [31:0] data [32] /* synthesis ramstyle = "logic" */ = '{default:'0};
logic [31:0] data [32];
logic write_through_a, write_through_b;
assign write_through_a = load & (dest == src_a);
assign write_through_b = load & (dest == src_b);

always_ff @(posedge clk)
begin
    if (rst)
    begin
        for (int i=0; i<32; i=i+1) begin
            data[i] <= '0;
        end
    end
    else if (load && dest)
    begin
        data[dest] <= in;
    end
end

always_comb
begin
    if(src_a)
        reg_a = write_through_a ? in : data[src_a];
    else
        reg_a = 32'h0;
    if(src_b)
        reg_b = write_through_b ? in : data[src_b];
    else
        reg_b = 32'h0;
end

endmodule : regfile
