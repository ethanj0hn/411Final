import rv32i_types::*; /* Import types defined in rv32i_types.sv */
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
// Internal Logic for IF
//
logic is_br, is_jump;
rv32i_opcode op_from_ex; // assign statement below line 60

// Internal Logic for Writeback
//
rv32i_word regfilemux_out;

// internal logic for EX
//
logic br_en;
rv32i_word alu_out;


always_comb
begin
    // default 0
    is_br = 1'b0;
    is_jump = 1'b0;
    unique case(op_from_ex)
        op_jal: // set is_jump on jal, jalr
            is_jump = 1'b1;
        op_jalr:
            is_jump = 1'b1;
        op_br:
            is_br = 1'b1;
        default : ;
    endcase
end

// Instruction fetch components
// Contains PC, PCmux
//
IF_stage IF(
    .clk(clk),
    .reset(reset),
    .br_en(br_en), // connect to br_en, br_cw, br_j from EX stage
    .br_cw(is_br),
    .j_cw(is_jump),
    .br_PC(alu_out), // alu output
    .inst_addr(inst_addr), // intruction add and read
    .inst_read(inst_read)
);

// Internal Logic for IR Shift regs
//
rv32i_word IR_IF_ID, IR_ID_EX, IR_EX_MEM, IR_MEM_WB;
assign op_from_ex = rv32i_opcode'(IR_ID_EX[6:0]);

// Shift regs for IR
//
shift_reg IR_regs(
    .clk(clk),
    .reset(reset),
    .load(1'b1), // always load for now
    .in(inst_rdata), // read from instruction data read from memory
    .IF_ID(IR_IF_ID), // has IF_ID IR value 
    .ID_EX(IR_ID_EX), // has ID_EX IR value
    .EX_MEM(IR_EX_MEM), // has EX_MEM IR value
    .MEM_WB(IR_MEM_WB) // has MEM_WV IR value
);

// Internal Logic for PC Shift regs
//
rv32i_word PC_IF_ID, PC_ID_EX, PC_EX_MEM, PC_MEM_WB;

// Shift regs for PC
//
shift_reg PC_regs(
    .clk(clk),
    .reset(reset),
    .load(1'b1), // always load for now
    .in(inst_addr), // read from PC out value
    .IF_ID(PC_IF_ID), // has IF_ID PC value 
    .ID_EX(PC_ID_EX), // has ID_EX PC value
    .EX_MEM(PC_EX_MEM), // has EX_MEM PC value
    .MEM_WB(PC_MEM_WB) // has MEM_WV PC value
);

// Internal Logic ID
//
rv32i_word reg_a, reg_b;
rv32i_control_word CW_regs_in;

// Internal Logic for control words
//
rv32i_control_word CW_ID_EX, CW_EX_MEM, CW_MEM_WB;

ID_stage ID (
    .clk(clk),
    .rst(reset),
    .funct3_if(IR_IF_ID[14:12]),
    .funct7_if(IR_IF_ID[31:25]),
    .opcode_if(rv32i_opcode'(IR_IF_ID[6:0])),
    .rs1_if(IR_IF_ID[19:15]),
    .rs2_if(IR_IF_ID[24:20]),
    .rs1_out_ex(reg_a),
    .rs2_out_ex(reg_b),
    .rd_wb(IR_MEM_WB[11:7]),
    .load_regfile_wb(CW_MEM_WB.load_regfile),
    .regfilemux_out_wb(regfilemux_out),
    .ctrl(CW_regs_in)
);
//internal logic for reg_a
//
logic [31:0] reg_a_buff_out;

register reg_a_buffer(
    .clk(clk),
    .rst(reset),
    .load(1'b1), // load is 1'b1 for now, change after adding caches
    .in(reg_a),
    .out(reg_a_buff_out)
);

//internal logic for reg_b
//
logic [31:0] reg_b_buff_out;

register reg_b_buffer(
    .clk(clk),
    .rst(reset),
    .load(1'b1), // load is 1'b1 for now, change after adding caches
    .in(reg_b),
    .out(reg_b_buff_out)
);

// shift reg for generated control words
//
shift_reg_cw CW_regs (
    .clk(clk),
    .reset(reset),
    .load(1'b1), // always load for now
    .in(CW_regs_in), // connect to output of decode stage
    .ID_EX(CW_ID_EX), // outputs for following stages
    .EX_MEM(CW_EX_MEM),
    .MEM_WB(CW_MEM_WB)
);

EX_stage EX(
    .reg_a(reg_a_buff_out),
    .PC_EX(PC_ID_EX),
    .alumux1_sel(CW_ID_EX.alumux1_sel),
    .IR_EX(IR_ID_EX),
    .reg_b(reg_b_buff_out),
    .alumux2_sel(CW_ID_EX.alumux2_sel),
    .cmpop(CW_ID_EX.cmpop), 
    .aluop(CW_ID_EX.aluop),
    .cmpmux_sel(CW_ID_EX.cmpmux_sel),
    .ALU_out(alu_out),
    .br_en(br_en)
);

// EX/MEM additional buffers
//

// Internal logic for alu_buffer
//
rv32i_word alu_buffer_exmem_out;

// buffer alu output after EX stage
//
register alu_buffer_exmem(
    .clk(clk),
    .rst(reset),
    .load(1'b1), // load is 1'b1 for now, change after adding caches
    .in(alu_out),
    .out(alu_buffer_exmem_out)
);

// buffer for cmp
//
logic br_en_exmem;
always_ff @(posedge clk)
begin
    if(reset)
        br_en_exmem <= 1'b0;
    else
        br_en_exmem <= br_en; // output from EX stage
end

// Internal logic for regb_buff
//
rv32i_word regb_buff_out_exmem;
// take reg_b and buffer in EX/MEM stage buffer
//
register regb_buff(
    .clk(clk),
    .rst(reset),
    .load(1'b1), // always load for now, change after adding caches
    .in(reg_b_buff_out),
    .out(regb_buff_out_exmem) // to memory
);

// Internal logic for MEM stage
//
logic [1:0] mem_address_last_two_bits;

// MEM stage logic
//
MEM_stage MEM(
    .clk(clk),
    .rst(reset),
    .funct3_mem(IR_EX_MEM[14:12]),

    // from exec buffers
    .rs2_out_buffered(regb_buff_out_exmem),
    .alu_buffered(alu_buffer_exmem_out), // calculated address

    // to wb buffer
    .mem_address_last_two_bits(mem_address_last_two_bits),

    // interfacing cache / memory
    .mem_wdata(data_wdata),
    .mem_address(data_addr),
    .mem_byte_enable(data_mbe)
);
// assign data read/write directly from control word
//
assign data_read = CW_EX_MEM.data_read;
assign data_write = CW_EX_MEM.data_write;

//Internal logic for buffer
//
rv32i_word mem_buff_out;

// Additional buffers for MEM/WB stage
//

logic [1:0] l_two_bits_buff;
always_ff @(posedge clk)
begin
    l_two_bits_buff <= mem_address_last_two_bits;
end

// Internal logic for alu_buffer
//
rv32i_word alu_buffer_memwb_out;

// buffer alu output after MEM stage
//
register alu_buffer_memwb(
    .clk(clk),
    .rst(reset),
    .load(1'b1), // load is 1'b1 for now, change after adding caches
    .in(alu_buffer_exmem_out),
    .out(alu_buffer_memwb_out)
);

// for buffering value read from memory
//
register data_memory_buffer(
    .clk  (clk),
    .rst (reset),
    .load (1'b1), // always load for now, change when integrating cache hit logic
    .in   (data_rdata),
    .out  (mem_buff_out)
);

// for buffering br_en from exec stage
//
logic br_en_memwb;
always_ff @(posedge clk)
begin
    if(reset)
        br_en_memwb <= 1'b0;
    else
        br_en_memwb <= br_en_exmem;
end

WB_stage WB(
    .data_value(mem_buff_out), // value read from memory
    .funct3(IR_MEM_WB[14:12]), 
    .br_en(br_en_memwb), // branch enable to load to register
    .alu_out(alu_buffer_memwb_out),
    .u_imm({IR_MEM_WB[31:12], 12'h000}),
    .pc_out(PC_MEM_WB),
    .mem_address_last_two_bits(l_two_bits_buff),
    .regfilemux_sel(CW_MEM_WB.regfilemux_sel), // regfile mux select
    .regfilemux_out_wb(regfilemux_out) // output of regfilemux
);

endmodule : pipeline_datapath