`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath
(
    input logic clk, // clk
    input logic rst, // reset
    input logic load_mar, // load mar
    input logic load_mdr, // load mdr, data out signals
    input logic load_data_out,
    input rv32i_word mem_rdata,
    input logic load_ir, // load ir signal
    input logic load_regfile, // load regfile
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input branch_funct3_t cmpop, // cmpop
    input cmpmux::cmpmux_sel_t cmpmux_sel, // cmpmux select
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input alu_ops aluop, // ALU op select
    input pcmux::pcmux_sel_t pcmux_sel, // pc mux select
    input logic load_pc, // load pc signal from control
    input marmux::marmux_sel_t marmux_sel, // marmux select 
    input logic [3:0] rmask_o, // for which bytes should be read/written
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    output rv32i_word mem_address,
    output [2:0] funct3, // outputs from IR
    output [6:0] funct7,
    output rv32i_opcode opcode,
    output logic br_en, // br_en control signal
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [1:0] mem_addr_mask // for load store in control
    /* You will need to connect more signals to your datapath module*/
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word mdrreg_out;
/*****************************************************************************/
// Internal logic for MDR if req
//

// Internal Logic for ir IR
//
logic [31:0] i_imm;
logic [31:0] s_imm;
logic [31:0] b_imm;
logic [31:0] u_imm;
logic [31:0] j_imm;
logic [4:0] rd;

// Internal Logic for RegfileMux RFM
//
rv32i_word regfilemux_out; 
rv32i_word lb, lh, lbu, lhu;
// based on bits that should be read/written to, assign lb, lbu, lh, lhu
//
always_comb
begin
    case (rmask_o)
        4'b0001: lb = { {24{mdrreg_out[7]}}, mdrreg_out[7:0]};
        4'b0010: lb = { {24{mdrreg_out[15]}}, mdrreg_out[15:8]};
        4'b0100: lb = { {24{mdrreg_out[23]}}, mdrreg_out[23:16]};
        4'b1000: lb = { {24{mdrreg_out[31]}}, mdrreg_out[31:24]};
        default: lb = { {24{mdrreg_out[23]}}, mdrreg_out[7:0]};
    endcase

    case (rmask_o)
        4'b0001: lbu = {24'b0, mdrreg_out[7:0]};
        4'b0010: lbu = {24'b0, mdrreg_out[15:8]};
        4'b0100: lbu = {24'b0, mdrreg_out[23:16]};
        4'b1000: lbu = {24'b0, mdrreg_out[31:24]};
        default: lbu = {24'b0, mdrreg_out[7:0]};
    endcase

    case (rmask_o)
        4'b0011: lhu = {16'b0, mdrreg_out[15:0]};
        4'b1100: lhu = {16'b0, mdrreg_out[31:16]};
        default: lhu = {16'b0, mdrreg_out[15:0]};
    endcase

    case (rmask_o)
        4'b0011: lh = { {16{mdrreg_out[15]}}, mdrreg_out[15:0]};
        4'b1100: lh = { {16{mdrreg_out[31]}}, mdrreg_out[31:16]};
        default: lh = { {16{mdrreg_out[15]}}, mdrreg_out[15:0]};
    endcase
end

//Internal Logic for RegFile
//
rv32i_word rs1_out, rs2_out;

//Internal Logic for alumux1
//
rv32i_word alumux1_out;

//Internal Logic for alumux2
//
rv32i_word alumux2_out;

//Internal Logic for ALU
//
rv32i_word alu_out;

//Internal Logic for PCMUX (already exists ^^)
//


//Internal Logic for PC
//
rv32i_word pc_plus4, pc_out;
assign pc_plus4 = pc_out + 4'h4;

//Internal Logic for MARMUX
//
rv32i_word marmux_out;

//Internal Logic for MAR
//
logic [31:0] mem_address_t;

assign mem_address = {mem_address_t[31:2],2'b00};
assign mem_addr_mask = mem_address_t[1:0];

// Internal logic/always comb for mem_data_out for sw instruction
//
rv32i_word mem_data_out_t;
logic [1:0] mem_addr_mask_sw;

assign mem_addr_mask_sw = marmux_out[1:0];

always_comb
begin
    case (store_funct3_t'(funct3))
        sw: mem_data_out_t = rs2_out;
        sh: 
        begin
            case (mem_addr_mask_sw)
                2'b00, 2'b01 : mem_data_out_t = {16'b0, rs2_out[15:0]};
                2'b10, 2'b11 : mem_data_out_t = {rs2_out[15:0], 16'b0};
                default: mem_data_out_t = rs2_out;
            endcase
        end

        sb:
        begin
            case (mem_addr_mask_sw)
                2'b00 : mem_data_out_t = {24'b0, rs2_out[7:0]};
                2'b01 : mem_data_out_t = {16'b0, rs2_out[7:0], 8'b0};
                2'b10 : mem_data_out_t = {8'b0, rs2_out[7:0], 16'b0};
                2'b11 : mem_data_out_t = {rs2_out[7:0], 24'b0};
                default : mem_data_out_t = rs2_out;
            endcase
        end

        default: mem_data_out_t = rs2_out;
    endcase
end 

//Internal Logic for CMPMUX
//
rv32i_word cmpmux_out;

//Internal Logic for CMP
//
rv32i_word cmp_out;

/***************************** Datapath *************************************/

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

//Keep Instruction register named `IR` for RVFI Monitor
ir IR(
    .clk(clk), 
    .rst(rst), 
    .load(load_ir), 
    .in(mdrreg_out),
    .*
    );

RegfileMUX RFM(
    .select(regfilemux_sel), 
    .in0(alu_out),
    .in1(cmp_out),
    .in2(u_imm),
    .in3(mdrreg_out),
    .in4(pc_plus4),
    .in5(lb),
    .in6(lbu),
    .in7(lh),
    .in8(lhu),
    .out(regfilemux_out)
    );

regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(load_regfile),
    .in(regfilemux_out),
    .src_a(rs1),
    .src_b(rs2),
    .dest(rd),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
    );

Two_to_one_MUX alumux1(
    .select(alumux1_sel),
    .in0(rs1_out),
    .in1(pc_out),
    .out(alumux1_out)    
    );

alumux2 alumux2(
    .*
    );

alu ALU(
    .aluop(aluop),
    .a(alumux1_out),
    .b(alumux2_out),
    .f(alu_out)
    );

PCMUX PCMUX(
    .select(pcmux_sel),
    .pc_plus4(pc_plus4),  
    .alu_out(alu_out),  
    .alu_mod2({alu_out[31:1], 1'b0}),
    .pcmux_out(pcmux_out) 
    );

pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)  
    );

Two_to_one_MUX MARMUX(
    .select(marmux_sel),
    .in0(pc_out),
    .in1(alu_out),
    .out(marmux_out)    
    );

register MAR(
    .clk(clk),
    .rst(rst),
    .load(load_mar),
    .in(marmux_out),
    .out(mem_address_t)  
    );

register mem_data_out(
    .clk(clk),
    .rst(rst),
    .load(load_data_out),
    .in(mem_data_out_t),
    .out(mem_wdata)  
    );

Two_to_one_MUX CMPMUX(
    .select(cmpmux_sel),
    .in0(rs2_out),
    .in1(i_imm),
    .out(cmpmux_out)
    );

cmp CMP(
    .br_func(cmpop),
    .in1(rs1_out),
    .in2(cmpmux_out),
    .br_en(br_en)
    );

assign cmp_out = {31'b0, br_en};




/*****************************************************************************/

/******************************* ALU and CMP *********************************/
/*****************************************************************************/

/******************************** Muxes **************************************/
// always_comb begin : MUXES
//     // We provide one (incomplete) example of a mux instantiated using
//     // a case statement.  Using enumerated types rather than bit vectors
//     // provides compile time type safety.  Defensive programming is extremely
//     // useful in SystemVerilog.  In this case, we actually use
//     // Offensive programming --- making simulation halt with a fatal message
//     // warning when an unexpected mux select value occurs
//     unique case (pcmux_sel)
//         pcmux::pc_plus4: pcumux_out = pc_out + 4;
//         // etc.
//         default: `BAD_MUX_SEL;
//     endcase
// end
/*****************************************************************************/
endmodule : datapath
