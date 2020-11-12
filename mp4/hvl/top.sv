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
assign rvfi.halt = 0;   // Set high when you detect an infinite loop
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
rv32i_opcode op_wb;
op_wb = dut.datapath.CW_MEM_WB.opcode;
logic halt;
assign halt = (op_wb == op_br) & (alu_out == dut.inst_addr);

always @(posedge itf.clk) begin
    if (halt)
        $finish;
    // if (timeout == 0) begin
    //     $display("TOP: Timed out");
    //     $finish;
    // end
    // timeout <= timeout - 1;
end
logic clk;
logic [31:0] data_rdata, data_addr, data_wdata, inst_rdata, alu_out, alu_buffer_exmem_out, alu_buffer_memwb_out;
logic [31:0] data_memory_buffer;
logic load_regfile;
rv32i_control_word CW_ID_EX, CW_EX_MEM, CW_MEM_WB;

assign clk = itf.clk;
assign inst_rdata = dut.inst_rdata;
assign inst_addr = dut.inst_addr;
assign data_rdata = dut.data_rdata;
assign data_addr = dut.data_addr;
assign data_wdata = dut.data_wdata;
assign data_memory_buffer = dut.datapath.data_memory_buffer.out;
assign load_regfile = dut.datapath.ID.load_regfile_wb;
assign CW_ID_EX = dut.datapath.CW_ID_EX;
assign CW_EX_MEM = dut.datapath.CW_EX_MEM;
assign CW_MEM_WB = dut.datapath.CW_MEM_WB;
assign alu_out = dut.datapath.alu_out;
assign alu_buffer_exmem_out = dut.datapath.alu_buffer_exmem_out;
assign alu_buffer_memwb_out = dut.datapath.alu_buffer_memwb_out;



mp4 dut(
    .clk(itf.clk),
    .reset(itf.rst),
    .data_resp(itf.data_resp), // response from data, instruction memory
    .inst_resp(itf.inst_resp),
    .inst_rdata(itf.inst_rdata), // instruction, data read port
    .data_rdata(itf.data_rdata),
    .inst_read(itf.inst_read), // instruction port address, read signal
    .inst_addr(itf.inst_addr),
    .data_read(itf.data_read), // data read write signals
    .data_write(itf.data_write), 
    .data_mbe(itf.data_mbe), // mem_byte_enable, signals data port address
    .data_addr(itf.data_addr), 
    .data_wdata(itf.data_wdata)  
);
/***************************** End Instantiation *****************************/

endmodule
