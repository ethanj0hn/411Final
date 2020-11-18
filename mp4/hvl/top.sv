import rv32i_types::*; /* Import types defined in rv32i_types.sv */
module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = 0; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = (dut.datapath.CW_MEM_WB.opcode == op_br) & (dut.datapath.alu_buffer_memwb_out == dut.datapath.PC_MEM_WB);   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/
always_comb
begin
    rvfi.inst = dut.datapath.inst_rdata;
    rvfi.trap = 0;
    rvfi.rs1_addr = dut.datapath.ID.regfile.src_a;
    rvfi.rs2_addr = dut.datapath.ID.regfile.src_b;
    rvfi.rs1_rdata = dut.datapath.ID.regfile.reg_a;
    rvfi.rs2_rdata = dut.datapath.ID.regfile.reg_b;
    rvfi.load_regfile = dut.datapath.ID.regfile.load;
    rvfi.rd_addr = dut.datapath.ID.regfile.dest;
    rvfi.rd_wdata = dut.datapath.ID.regfile.in;
    rvfi.pc_wdata = dut.datapath.IF.PC.in;
    rvfi.pc_rdata = dut.datapath.IF.PC.out;
    rvfi.mem_addr = dut.mem_addr;
    rvfi.mem_rmask = dut.datapath.rmask;
    rvfi.mem_wmask = dut.datapath.MEM.mem_byte_enable;
    rvfi.mem_rdata = dut.mem_rdata;
    rvfi.mem_wdata = dut.mem_wdata;
end

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

// halt condition
// if opcode j or br wb and alu_out is PC
//
// logic halt;
// assign halt = (dut.datapath.CW_MEM_WB.opcode == op_br) & (dut.datapath.alu_buffer_memwb_out == dut.datapath.PC_MEM_WB);

always @(posedge itf.clk) begin
    if (rvfi.halt)
        $finish;
    // if (timeout == 0) begin
    //     $display("TOP: Timed out");
    //     $finish;
    // end
    // timeout <= timeout - 1;
end
logic clk,br_en,br_cw,j_cw,take_branch;
logic [31:0] data_rdata, data_addr, data_wdata, inst_rdata, alu_out, alu_buffer_exmem_out, alu_buffer_memwb_out, inst_addr;
logic [31:0] data_memory_buffer;
logic load_regfile;
rv32i_control_word CW_ID_EX, CW_EX_MEM, CW_MEM_WB;
branchmux::branchmux_sel_t branchmux_sel;
rv32i_control_word ctrl;

assign clk = itf.clk;
assign br_en = dut.datapath.br_en; // branch enable from datapath
assign br_cw = dut.datapath.is_br; // branch operation from execute variable
assign j_cw = dut.datapath.is_jump; // jump operation from execute variable
assign take_branch = dut.datapath.take_branch; // should you take branch?
assign inst_addr = dut.inst_addr; // top level signals
assign inst_rdata = dut.inst_rdata;
assign data_rdata = dut.data_rdata;
assign data_addr = dut.data_addr;
assign data_wdata = dut.data_wdata;
assign data_memory_buffer = dut.datapath.data_memory_buffer.out; // what's being read from data memory
assign load_regfile = dut.datapath.ID.load_regfile_wb; // load regfile signal
assign CW_ID_EX = dut.datapath.CW_ID_EX; // control words in IDEX, EXMEM, MEMWB
assign CW_EX_MEM = dut.datapath.CW_EX_MEM;
assign CW_MEM_WB = dut.datapath.CW_MEM_WB;
assign alu_out = dut.datapath.alu_out; // alu_out
assign alu_buffer_exmem_out = dut.datapath.alu_buffer_exmem_out; // alu buffer outputs
assign alu_buffer_memwb_out = dut.datapath.alu_buffer_memwb_out;
assign branchmux_sel = dut.datapath.ID.branchmux_sel; // branch mux select in datapath
assign ctrl = dut.datapath.ID.ctrl; // generated control word



mp4 dut(
    .clk(itf.clk),
    .reset(itf.rst),
    .mem_resp(itf.mem_resp),
    .mem_rdata(itf.mem_rdata),
    .mem_read(itf.mem_read),
    .mem_addr(itf.mem_addr),
    .mem_wdata(itf.mem_wdata),
    .mem_write(itf.mem_write)
);

/***************************** End Instantiation *****************************/

endmodule
