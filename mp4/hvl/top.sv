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
int timeout = 100000000;
/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2
integer i,j,k,l;
initial begin
    i = $fopen("mp4_regoutput.txt","w");
    j = $fopen("mp4_regtimeout.txt","w");
    k = $fopen("mp4_loadstore.txt","w");
    l = $fopen("mp4_lstimeout.txt", "w");
end

assign rvfi.commit = 0; //dut.datapath.ID.regfile.load | dut.datapath.IF.PC.load; // Set high when a valid instruction is modifying regfile or PC
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
    rvfi.rs2_addr
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


assign itf.inst_read = dut.datapath.inst_read;
assign itf.inst_addr = dut.datapath.inst_addr;
assign itf.inst_resp = dut.datapath.inst_resp;
assign itf.inst_rdata = dut.datapath.inst_rdata;

assign itf.data_read = dut.datapath.data_read;
assign itf.data_write = dut.datapath.data_write;
assign itf.data_mbe = dut.datapath.data_mbe;
assign itf.data_addr = dut.datapath.data_addr;
assign itf.data_wdata = dut.datapath.data_wdata;
assign itf.data_resp = dut.datapath.data_resp;
assign itf.data_rdata = dut.datapath.data_rdata;



/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.datapath.ID.regfile.data;

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
logic regfile_load, pipeline_en;
logic [31:0] regfile_in, PC_out;
logic [4:0] regfile_addr;
rv32i_opcode EX_MEM_opcode;

always_comb
begin
    regfile_load = dut.datapath.ID.regfile.load;
    regfile_in = dut.datapath.ID.regfile.in;
    PC_out = dut.datapath.PC_MEM_WB;
    regfile_addr = dut.datapath.ID.regfile.dest;
    EX_MEM_opcode = dut.datapath.CW_EX_MEM.opcode;
    pipeline_en = dut.datapath.pipeline_en;
end

always @(posedge itf.clk) begin
    if (rvfi.halt)
        $finish;
    // if (timeout == 0) begin
    //     $display("TOP: Timed out");
    //     $finish;
    // end
    timeout <= timeout - 1;
    if (regfile_load & regfile_addr)
    begin
		$fwrite(i,"-PC is %x, input to regfile is %x, address is %d\n",PC_out,regfile_in,regfile_addr);
        $fwrite(j,"Time (regfile commit) in ns is %d\n",$time / 1000);
    end
    if ((EX_MEM_opcode == op_load) & pipeline_en)
    begin
        $fwrite(i,"On load, PC is %x, mem_address is %x, read data is %x, dest reg address is %d\n", 
            dut.datapath.PC_EX_MEM, dut.datapath.data_addr, dut.datapath.data_rdata, dut.datapath.IR_EX_MEM[11:7]);
        $fwrite(j,"Time (load) in ns is %d\n",$time / 1000);
    end
    if ( (EX_MEM_opcode == op_store) & pipeline_en)
    begin
        $fwrite(i, "On store, PC is %x, mem_address is %x, write data is %x, mbe is %b\n", 
            dut.datapath.PC_EX_MEM, dut.datapath.data_addr, dut.datapath.data_wdata, dut.datapath.data_mbe);
        $fwrite(j,"Time (store) in ns is %d\n",$time / 1000);
    end
end
logic clk,br_en,br_cw,j_cw,take_branch;
logic [31:0] data_rdata, data_addr, data_wdata, inst_rdata, alu_out, alu_buffer_exmem_out, alu_buffer_memwb_out, inst_addr;
logic [31:0] data_memory_buffer;
logic [31:0] registers [32];
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

for(genvar i = 0; i<32;i++)
assign registers[i] = dut.datapath.ID.regfile.data[i];

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
