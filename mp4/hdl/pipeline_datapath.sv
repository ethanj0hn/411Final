/*
Module integrating all pieces of the pipeline.
Inputs - clk, reset, memory signals as descrbed below
Outputs - memory signals as described below
*/
module pipeline_datapath(
    input logic clk,
    input logic reset,
    input logic data_resp, // response from data, instruction memory
    input logic inst_resp,
    input logic [31:0] inst_rdata, // instruction, data read port
    input logic [31:0] data_rdata,
    output logic inst_read, // instruction port address, read signal
    output logic [31:0] inst_addr,
    output logic data_read, // data read write signals
    output logic data_write, 
    output logic [3:0] data_mbe, // mem_byte_enable, signals data port address
    output logic [31:0] data_addr, 
    output logic [31:0] data_wdata
);

// Instruction fetch components
// Contains PC, PCmux
//
IF_stage IF(
    .clk(clk),
    .reset(reset),
    .br_en(), // connect to br_en, br_cw, br_j from EX stage
    .br_cw(),
    .j_cw(),
    .br_PC(), // alu output
    .inst_addr(inst_addr), // intruction add and read
    .inst_read(inst_read)
);

// Shift regs for IR
//
shift_reg IR_regs(
    .clk(clk),
    .reset(reset),
    .load(1'b1), // always load for now
    .in(inst_rdata), // read from instruction data read from memory
    .IF_ID(), // has IF_ID IR value 
    .ID_EX(), // has ID_EX IR value
    .EX_MEM(), // has EX_MEM IR value
    .MEM_WB() // has MEM_WV IR value
);

// Shift regs for PC
//
shift_reg PC_regs(
    .clk(clk),
    .reset(reset),
    .load(1'b1), // always load for now
    .in(inst_addr), // read from PC out value
    .IF_ID(), // has IF_ID PC value 
    .ID_EX(), // has ID_EX PC value
    .EX_MEM(), // has EX_MEM PC value
    .MEM_WB() // has MEM_WV PC value
);

ID_stage ID (
    .clk(clk),
    .rst(rst),
    .funct3_if(),
    .funct7_if(),
    .opcode_if(),
    .rs1_ex(),
    .rs2_ex(),
    .rs1_out_ex(),
    .rs2_out_ex(),
    .rd_wb(),
    .load_regfile_wb(),
    .regfilemux_out_wb(),
    .ctrl()
);

// shift reg for generated control words
//
// TODO: add width in paramter below and connect
shift_reg_cw CW_regs (
    .clk(clk),
    .reset(reset),
    .load(1'b1), // always load for now
    .in(), // connect to output of decode stage
    .ID_EX(), // outputs for following stages
    .EX_MEM(),
    .MEM_WB()
);

MEM_stage MEM (
    .clk(clk),
    .rst(rst),
    .ctrl(),

    // from current IR
    .funct3_mem(),

    // from exec
    .rs2_out(),
    .alu_buffered(), // calculated address
    .funct3_exec(),

    // to wb
    .data_value(), // data from data_value_register

    // interfacing cache / memory
    .mem_rdata(),
    .mem_wdata(),
    .mem_address(),
    .mem_byte_enable(),
    .data_read(),
    .data_write()
);



endmodule : pipeline_datapath