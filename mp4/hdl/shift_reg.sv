import rv32i_types::*; /* Import types defined in rv32i_types.sv */
/*
Shift regs for PC
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
logic [31:0] data [4];   //stores value for 4 pipeline registers

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
always_ff @(posedge clk)
begin
    if(reset)
    begin
        for(int i=0;i<4;i++)
        begin
            data[i] <= 32'h0;
        end
    end
    else if(load)
    begin
        data[0] <= in;  // IF_ID gets data post IF 

        for(int i=1; i<4; i++)
        begin
            data[i] <= data[i-1];  //every cycle data from previous stage goes to next
        end
    end
    else
    begin
        for(int i=0; i<4; i++)
        begin
            data[i] <= data[i];
        end
    end
end

endmodule : shift_reg

/*
Shift regs for IR
Inputs - clk,reset, load, in
Outputs- 32 bit words for buffers
*/
module shift_reg_IR(
    input logic clk,
    input logic reset,
    input logic load,
    input branchmux::branchmux_sel_t branchmux_sel, // for clearing IR on a branch clear
    input logic [31:0] in, // input in the beginning
    output logic [31:0] IF_ID, // output for each stage in pipeline
    output logic [31:0] ID_EX,
    output logic [31:0] EX_MEM,
    output logic [31:0] MEM_WB
);

// internal logic and assignments
//
logic [31:0] data [4];   //stores value for 4 pipeline registers

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
always_ff @(posedge clk)
begin
    if(reset)
    begin
        for(int i=0;i<4;i++)
        begin
            data[i] <= 32'h0;
        end
    end
    else if(load)
    begin
        data[0] <= in;  // IF_ID gets data post IF 

        // if branch mispredict, clear IR. for now static not taken, so if branch taken, clear
        //
        if (branchmux_sel == branchmux::br_taken) 
            data[1] <= 32'h0;
        else
            data[1] <= data[0];

        for(int i=2; i<4; i++)
        begin
            data[i] <= data[i-1];  //every cycle data from previous stage goes to next
        end
    end
    else
    begin
        for(int i=0; i<4; i++)
        begin
            data[i] <= data[i];
        end
    end
end

endmodule : shift_reg_IR

/*
Shift regs for control word
Inputs - clk,reset, load, in
Outputs- control word struct
*/
module shift_reg_cw 
(
    input logic clk,
    input logic reset,
    input logic load,
    input rv32i_control_word in, // input in the beginning
    output rv32i_control_word ID_EX, // output for each stage in pipeline
    output rv32i_control_word EX_MEM,
    output rv32i_control_word MEM_WB
);

//internal logic and assignments
//
rv32i_control_word data [3]; //control word logic assigned in decode stage, used for 3 pipeline reg

always_comb
begin
    ID_EX = data[0];
    EX_MEM = data[1];
    MEM_WB = data[2];
end

// assign 0's on reset, shift on load
// else retain data
//
always_ff @(posedge clk)
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
            data[i] <= data[i];
        end
    end
end

endmodule : shift_reg_cw
