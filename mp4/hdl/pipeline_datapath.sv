/*
Module integrating all pieces of the pipeline.
Inputs - clk, reset, memory signals as descrbed below
Outputs - memory signals as described below
*/

import rv32i_types::*; /* Import types defined in rv32i_types.sv */

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
rv32i_word IR_regs_in;
rv32i_opcode op_from_ex; // assign statement below line 60

// Internal Logic for Writeback
//
rv32i_word regfilemux_out;

// internal logic for EX
//
logic br_en, take_branch;
rv32i_word alu_out;
branchmux::branchmux_sel_t branchmux_sel;

// controlling pipeline run / stall
logic pipeline_en;
assign pipeline_en = inst_resp & (data_resp | (~data_read & ~data_write));

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

// if branch instruction in execute and condition holds, take branch
//
assign take_branch = is_br & br_en;

// also load PC/appropriate control words on jumps
//
assign branchmux_sel = branchmux::branchmux_sel_t'(take_branch | is_jump);

// Instruction fetch components
// Contains PC, PCmux
//
IF_stage IF(
    .clk(clk),
    .reset(reset),
    .branchmux_sel(branchmux_sel),
    .pipeline_en(pipeline_en),
    .br_PC(alu_out), // alu output
    .inst_rdata(inst_rdata),
    .inst_addr(inst_addr), // intruction add and read
    .inst_read(inst_read),
    .IR_regs_in(IR_regs_in) // to shift regs
);

// Internal Logic for IR Shift regs
//
rv32i_word IR_IF_ID, IR_ID_EX, IR_EX_MEM, IR_MEM_WB;

// Shift regs for IR
//
shift_reg IR_regs(
    .clk(clk),
    .reset(reset),
    .load(pipeline_en), // always load for now
    .in(IR_regs_in), // read from instruction data read from memory
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
    .load(pipeline_en), // always load for now
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
assign op_from_ex = CW_ID_EX.opcode;

ID_stage ID (
    .clk(clk),
    .rst(reset),
    .branchmux_sel(branchmux_sel),
    .pipeline_en(pipeline_en),
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
    .load(pipeline_en), // load is 1'b1 for now, change after adding caches
    .in(reg_a),
    .out(reg_a_buff_out)
);

//internal logic for reg_b
//
logic [31:0] reg_b_buff_out;

register reg_b_buffer(
    .clk(clk),
    .rst(reset),
    .load(pipeline_en), // load is 1'b1 for now, change after adding caches
    .in(reg_b),
    .out(reg_b_buff_out)
);

// assigning logic for IR bits to make code more readable
//
logic [4:0] rs1_idex, rs2_idex, rs2_exmem, rd_exmem, rd_memwb;

assign rs1_idex = IR_ID_EX[19:15];
assign rs2_idex = IR_ID_EX[24:20];
assign rs2_exmem = IR_EX_MEM[24:20];
assign rd_exmem = IR_EX_MEM[11:7];
assign rd_memwb = IR_MEM_WB[11:7];

// Logic for regfilemux selects, source registers and forwarding and assign statements
//
regfilemux::regfilemux_sel_t regfilemux_sel_exmem, regfilemux_sel_memwb;
fwd::fwd_sel_t alumux1_fwd_sel_exmem, alumux2_fwd_sel_exmem, alumux1_fwd_sel_memwb, alumux2_fwd_sel_memwb, wdata_fwd_sel;

always_comb
begin
    // Assign regfilemux sels
    //
    regfilemux_sel_exmem = CW_EX_MEM.regfilemux_sel;
    regfilemux_sel_memwb = CW_MEM_WB.regfilemux_sel;

    // Assign use_fwd if src ex = dest mem
    //
    alumux1_fwd_sel_exmem = fwd::fwd_sel_t'((rs1_idex == rd_exmem) & (rs1_idex != 4'b0000)); 
    alumux2_fwd_sel_exmem = fwd::fwd_sel_t'((rs2_idex == rd_exmem) & (rs2_idex != 4'b0000));

    // Assign use_fwd if src ex = dest wb
    //
    alumux1_fwd_sel_memwb = fwd::fwd_sel_t'((rs1_idex == rd_memwb) & (rs1_idex != 4'b0000)); 
    alumux2_fwd_sel_memwb = fwd::fwd_sel_t'((rs2_idex == rd_memwb) & (rs2_idex != 4'b0000));

    // Assign use_fwd if rs2_exmem (register used for writing data to memory) = rd wb
    //
    wdata_fwd_sel = fwd::fwd_sel_t'((rs2_exmem == rd_memwb));
end

// shift reg for generated control words
//
shift_reg_cw CW_regs (
    .clk(clk),
    .reset(reset),
    .load(pipeline_en), // always load for now
    .in(CW_regs_in), // connect to output of decode stage
    .ID_EX(CW_ID_EX), // outputs for following stages
    .EX_MEM(CW_EX_MEM),
    .MEM_WB(CW_MEM_WB)
);

// internal logic for ex. Assigned by regfilemux selects after appropriate buffers below.
//
logic [31:0] rd_fwd_exmem, rd_fwd_memwb;

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
    .rd_fwd_exmem(rd_fwd_exmem),
    .rd_fwd_memwb(rd_fwd_memwb),
    .alumux1_fwd_sel_exmem(alumux1_fwd_sel_exmem), // alumux selects for forwarding logic from 2 future stages
    .alumux2_fwd_sel_exmem(alumux2_fwd_sel_exmem),
    .alumux1_fwd_sel_memwb(alumux1_fwd_sel_memwb),
    .alumux2_fwd_sel_memwb(alumux2_fwd_sel_memwb),
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
    .load(pipeline_en), // load is 1'b1 for now, change after adding caches
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
    else if (pipeline_en)
        br_en_exmem <= br_en; // output from EX stage
    else
        br_en_exmem <= br_en_exmem;
end

// Internal logic for regb_buff
//
rv32i_word regb_buff_out_exmem;
// take reg_b and buffer in EX/MEM stage buffer
//
register regb_buff(
    .clk(clk),
    .rst(reset),
    .load(pipeline_en), // always load for now, change after adding caches
    .in(reg_b_buff_out),
    .out(regb_buff_out_exmem) // to memory
);

// Internal logic for MEM stage
//
logic [1:0] mem_address_last_two_bits;

// regfilemux logic for exmem buffer forwarding
// load forwarding results omitted as not available in exmem buffer
//
always_comb
begin
    unique case (regfilemux_sel_exmem)
        regfilemux::br_en:
            rd_fwd_exmem = {31'b0,br_en_exmem};
        regfilemux::u_imm:
            rd_fwd_exmem = {IR_EX_MEM[31:12], 12'h000};
        regfilemux::pc_plus4:
            rd_fwd_exmem = (PC_EX_MEM + 32'h4);
        regfilemux::alu_out:
            rd_fwd_exmem = alu_buffer_exmem_out;
        
        // if read data is needed cycle after read from memory, forwarding logic
        //
        regfilemux::lw:
            rd_fwd_exmem = data_rdata;
        regfilemux::lb:
        begin
            case (mem_address_last_two_bits)
                2'b00:
                    rd_fwd_exmem = { {24{data_rdata[7]}}, data_rdata[7:0]};
                2'b01:
                    rd_fwd_exmem = { {24{data_rdata[15]}}, data_rdata[15:8]};
                2'b10:
                    rd_fwd_exmem = { {24{data_rdata[23]}}, data_rdata[23:16]};
                2'b11:
                    rd_fwd_exmem = { {24{data_rdata[31]}}, data_rdata[31:24]};
                default:
                    rd_fwd_exmem = { {24{data_rdata[15]}}, data_rdata[15:8]};
            endcase
        end
        regfilemux::lbu:
        begin
            case (mem_address_last_two_bits)
                2'b00:
                    rd_fwd_exmem = {24'b0, data_rdata[7:0]};
                2'b01:
                    rd_fwd_exmem = {24'b0, data_rdata[15:8]};
                2'b10:
                    rd_fwd_exmem = {24'b0, data_rdata[23:16]};
                2'b11:
                    rd_fwd_exmem = {24'b0, data_rdata[31:24]};
                default:
                    rd_fwd_exmem = {24'b0, data_rdata[15:8]};   
            endcase
        end
        regfilemux::lh:
        begin
            case (mem_address_last_two_bits)
                2'b00, 2'b01:
                    rd_fwd_exmem = { {16{data_rdata[15]}}, data_rdata[15:0]};
                2'b10, 2'b11:
                    rd_fwd_exmem = { {16{data_rdata[31]}}, data_rdata[31:16]};
                default:
                    rd_fwd_exmem = { {16{data_rdata[15]}}, data_rdata[15:0]};
            endcase
        end
        regfilemux::lhu:
        begin
            case (mem_address_last_two_bits)
                2'b00, 2'b01:
                    rd_fwd_exmem = {16'b0, data_rdata[15:0]};
                2'b10, 2'b11:
                    rd_fwd_exmem = {16'b0, data_rdata[31:16]};
                default:
                    rd_fwd_exmem = {16'b0, data_rdata[15:0]};
            endcase
        end
        default:
            rd_fwd_exmem = alu_buffer_exmem_out;
    endcase
end

//Internal logic for buffer
//
rv32i_word mem_buff_out;

// MEM stage logic
//
MEM_stage MEM(
    .clk(clk),
    .rst(reset),
    .funct3_mem(IR_EX_MEM[14:12]),

    // from exec buffers
    .rs2_out_buffered(regb_buff_out_exmem),
    .alu_buffered(alu_buffer_exmem_out), // calculated address

    // fwding selects and reg values
    .wdata_fwd_sel(wdata_fwd_sel),
    .rs2_fwd_memwb(mem_buff_out),

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

// Additional buffers for MEM/WB stage
//

logic [1:0] l_two_bits_buff;
always_ff @(posedge clk)
begin
    if (reset)
        l_two_bits_buff <= 2'b00;
    else if (pipeline_en)
        l_two_bits_buff <= mem_address_last_two_bits;
    else
        l_two_bits_buff <= l_two_bits_buff;
end

// Internal logic for alu_buffer
//
rv32i_word alu_buffer_memwb_out;

// buffer alu output after MEM stage
//
register alu_buffer_memwb(
    .clk(clk),
    .rst(reset),
    .load(pipeline_en), // load is 1'b1 for now, change after adding caches
    .in(alu_buffer_exmem_out),
    .out(alu_buffer_memwb_out)
);

// for buffering value read from memory
//
register data_memory_buffer(
    .clk  (clk),
    .rst (reset),
    .load (pipeline_en), // always load for now, change when integrating cache hit logic
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
    else if (pipeline_en)
        br_en_memwb <= br_en_exmem;
    else
        br_en_memwb <= br_en_memwb;
end

// regfilemux logic for memwb buffer forwarding, case statements based off of last 2 bits
//
always_comb
begin
    unique case (regfilemux_sel_memwb)
        regfilemux::alu_out:
            rd_fwd_memwb = alu_buffer_memwb_out;
        regfilemux::br_en:
            rd_fwd_memwb = {31'b0,br_en_memwb};
        regfilemux::u_imm:
            rd_fwd_memwb = {IR_MEM_WB[31:12], 12'h000};
        regfilemux::lw:
            rd_fwd_memwb = mem_buff_out;
        regfilemux::pc_plus4:
            rd_fwd_memwb = (PC_MEM_WB + 32'h4);
        regfilemux::lb:
        begin
            case (l_two_bits_buff)
                2'b00:
                    rd_fwd_memwb = { {24{mem_buff_out[7]}}, mem_buff_out[7:0]};
                2'b01:
                    rd_fwd_memwb = { {24{mem_buff_out[15]}}, mem_buff_out[15:8]};
                2'b10:
                    rd_fwd_memwb = { {24{mem_buff_out[23]}}, mem_buff_out[23:16]};
                2'b11:
                    rd_fwd_memwb = { {24{mem_buff_out[31]}}, mem_buff_out[31:24]};
                default:
                    rd_fwd_memwb = { {24{mem_buff_out[15]}}, mem_buff_out[15:8]};
            endcase
        end
        regfilemux::lbu:
        begin
            case (l_two_bits_buff)
                2'b00:
                    rd_fwd_memwb = {24'b0, mem_buff_out[7:0]};
                2'b01:
                    rd_fwd_memwb = {24'b0, mem_buff_out[15:8]};
                2'b10:
                    rd_fwd_memwb = {24'b0, mem_buff_out[23:16]};
                2'b11:
                    rd_fwd_memwb = {24'b0, mem_buff_out[31:24]};
                default:
                    rd_fwd_memwb = {24'b0, mem_buff_out[15:8]};   
            endcase
        end
        regfilemux::lh:
        begin
            case (l_two_bits_buff)
                2'b00, 2'b01:
                    rd_fwd_memwb = { {16{mem_buff_out[15]}}, mem_buff_out[15:0]};
                2'b10, 2'b11:
                    rd_fwd_memwb = { {16{mem_buff_out[31]}}, mem_buff_out[31:16]};
                default:
                    rd_fwd_memwb = { {16{mem_buff_out[15]}}, mem_buff_out[15:0]};
            endcase
        end
        regfilemux::lhu:
        begin
            case (l_two_bits_buff)
                2'b00, 2'b01:
                    rd_fwd_memwb = {16'b0, mem_buff_out[15:0]};
                2'b10, 2'b11:
                    rd_fwd_memwb = {16'b0, mem_buff_out[31:16]};
                default:
                    rd_fwd_memwb = {16'b0, mem_buff_out[15:0]};
            endcase
        end
        default:
            rd_fwd_memwb = alu_buffer_memwb_out;
    endcase
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