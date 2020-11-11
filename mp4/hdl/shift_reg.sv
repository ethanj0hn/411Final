/*
Shift regs for PC and IR
Inputs - clk,reset, load, in
Outputs- 32 bit words for buffers
*/
module shift_reg(
    input logic clk,
    input logic reset,
    input logic load,
    input logic [31:0] in, // input in the beginning
    output logic [31:0] IF_ID, // output for each stage in pipeline
    output logic [31:0] ID_EX,
    output logic [31:0] EX_MEM,
    output logic [31:0] MEM_WB
);

// internal logic and assignments
//
logic [31:0] data [4];

always_comb
begin
    IF_ID = data[0];
    ID_EX = data[1];
    EX_MEM = data[2];
    MEM_WB = data[3];
end

// assign 0's on reset, shift on load
// else retain data
//
always_ff(@posedge clk)
begin
    if(reset)
    begin
        for(int i=0;i<4;i++)
        begin
            data[i] = 32'h0;
        end
    end
    else if(load)
    begin
        data[0] <= in;

        for(int i=1; i<4; i++)
        begin
            data[i] <= data[i-1];
        end
    end
    else
    begin
        for(int i=0; i<4; i++)
        begin
            data[i] <= data[i]
        end
    end
end

endmodule : shift_reg

/*
Shift regs for control word
Inputs - clk,reset, load, in
Outputs- s_width bit words for buffers
*/
module shift_reg_cw #(parameter s_width = 32) // add length here
(
    input logic clk,
    input logic reset,
    input logic load,
    input logic [s_width-1:0] in, // input in the beginning
    output logic [s_width-1:0] ID_EX, // output for each stage in pipeline
    output logic [s_width-1:0] EX_MEM,
    output logic [s_width-1:0] MEM_WB
);

//internal logic and assignments
//
logic [s_width-1:0] data [3];

always_comb
begin
    ID_EX = data[0];
    EX_MEM = data[1];
    MEM_WB = data[2];
end

// assign 0's on reset, shift on load
// else retain data
//
always_ff(@posedge clk)
begin
    if(reset)
    begin
        for(int i=0;i<3;i++)
        begin
            data[i] = 0;
        end
    end
    else if(load)
    begin
        data[0] <= in;

        for(int i=1; i<3; i++)
        begin
            data[i] <= data[i-1];
        end
    end
    else
    begin
        for(int i=0; i<3; i++)
        begin
            data[i] <= data[i]
        end
    end
end

endmodule : shift_reg_cw
