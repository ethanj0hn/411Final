`define SRC 0
`define RAND 1
`define TESTBENCH `SRC
import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module mp2_tb;

timeunit 1ns;
timeprecision 1ns;

/****************************** Generate Clock *******************************/
bit clk;
always #5 clk = clk === 1'b0;


/*********************** Variable/Interface Declarations *********************/
logic commit;
assign commit = dut.load_pc;
tb_itf itf(clk);
logic [63:0] order;
initial order = 0;
always @(posedge itf.clk iff commit) order <= order + 1;
int timeout = 100000000;   // Feel Free to adjust the timeout value
assign itf.registers = dut.datapath.regfile.data;
assign itf.halt = dut.load_pc & (dut.datapath.pc_out == dut.datapath.pcmux_out);
/*****************************************************************************/

/************************** Testbench Instantiation **************************/
// source_tb --- drives the dut by executing a RISC-V binary
// random_tb --- drives the dut by generating random input vectors
generate
if (`TESTBENCH == `SRC) begin : testbench
    source_tb tb(.mem_itf(itf));
end
else begin : testbench
    random_tb tb(.itf(itf), .mem_itf(itf));
end
endgenerate

integer f,g,h,i;
// Initial Reset
initial begin
    itf.rst = 1'b1;
    repeat (5) @(posedge clk);
    itf.rst = 1'b0;
    // for(int i = 1; i < 30; i++)
    // begin
    //     dut.datapath.regfile.data[i] = i;
    // end
	f = $fopen("mp2_regoutput.txt","w");
    g = $fopen("mp2_regtimeout.txt", "w");
    h = $fopen("mp2_loadstore.txt","w");
    i = $fopen("mp2_lstimeout.txt", "w");
end

logic loadmar, loadmdr,mem_resp,mem_read,mem_write;
logic [31:0] data [32];
logic [31:0] mdr,mar,pc,pcin,mem_address,alu1in,alu2in,aluout,marmuxsel,marmux0,marmux1,marin,
    alumux1_0,alumux1_1,alumux1_sel,rs1,rs2,dest,reg_a,reg_b,mem_rdata,mem_wdata;
states State;
logic [4:0] rd;

assign loadmar = dut.datapath.load_mar;
assign loadmdr = dut.datapath.load_mdr;
assign mdr = dut.datapath.MDR.out;
assign mar = dut.datapath.MAR.out;
assign State = dut.control.State;
assign pc = dut.datapath.PC.out;
assign pcin = dut.datapath.PC.in;
assign mem_address = dut.mem_address;
assign alu1in = dut.datapath.ALU.a;
assign alu2in = dut.datapath.ALU.b;
assign aluout = dut.datapath.ALU.f;
assign marmux0 = dut.datapath.MARMUX.in0;
assign marmux1 = dut.datapath.MARMUX.in1;
assign marin = dut.datapath.MAR.in;
assign marmuxsel = dut.datapath.marmux_sel;
assign alumux1_0 = dut.datapath.rs1_out;
assign alumux1_1 = dut.datapath.pc_out;
assign alumux1_sel = dut.datapath.alumux1_sel;
assign rs1 = dut.datapath.rs1;
assign rs2 = dut.datapath.rs2;
assign dest = dut.datapath.regfile.dest;
assign reg_a = dut.datapath.regfile.reg_a;
assign reg_b = dut.datapath.regfile.reg_b;
assign mem_wdata = dut.mem_wdata;
assign mem_rdata = dut.mem_rdata;
assign mem_resp = dut.mem_resp;
assign mem_read = dut.mem_read;
assign mem_write = dut.mem_write;
/*****************************************************************************/
logic regfile_load;
logic [31:0] regfile_in, PC_out;
logic [4:0] regfile_addr;

always_comb
begin
    regfile_load = dut.datapath.regfile.load;
    regfile_in = dut.datapath.regfile.in;
    PC_out = dut.datapath.regfile.PC_out;
    regfile_addr = dut.datapath.regfile.dest;
    rd = dut.datapath.IR.rd;
end




mp2 dut(
    .clk             (itf.clk),
    .rst             (itf.rst),
    .mem_resp        (itf.mem_resp),
    .mem_rdata       (itf.mem_rdata),
    .mem_read        (itf.mem_read),
    .mem_write       (itf.mem_write),
    .mem_byte_enable (itf.mem_byte_enable),
    .mem_address     (itf.mem_address),
    .mem_wdata       (itf.mem_wdata)
);

riscv_formal_monitor_rv32i monitor(
    .clock (itf.clk),
    .reset (itf.rst),
    .rvfi_valid (commit),
    .rvfi_order (order),
    .rvfi_insn (dut.datapath.IR.data),
    .rvfi_trap(dut.control.trap),
    .rvfi_halt(itf.halt),
    .rvfi_intr(1'b0),
    .rvfi_mode(2'b00),
    .rvfi_rs1_addr(dut.control.rs1_addr),
    .rvfi_rs2_addr(dut.control.rs2_addr),
    .rvfi_rs1_rdata(monitor.rvfi_rs1_addr ? dut.datapath.rs1_out : 0),
    .rvfi_rs2_rdata(monitor.rvfi_rs2_addr ? dut.datapath.rs2_out : 0),
    .rvfi_rd_addr(dut.load_regfile ? dut.datapath.rd : 5'h0),
    .rvfi_rd_wdata(monitor.rvfi_rd_addr ? dut.datapath.regfilemux_out : 0),
    .rvfi_pc_rdata(dut.datapath.pc_out),
    .rvfi_pc_wdata(dut.datapath.pcmux_out),
    .rvfi_mem_addr(itf.mem_address),
    .rvfi_mem_rmask(dut.control.rmask),
    .rvfi_mem_wmask(dut.control.wmask),
    .rvfi_mem_rdata(dut.datapath.mdrreg_out),
    .rvfi_mem_wdata(dut.datapath.mem_wdata),
    .rvfi_mem_extamo(1'b0),
    .errcode(itf.errcode)
);

/************************* Error Halting Conditions **************************/
// Stop simulation on error detection
always @(itf.errcode iff (itf.errcode != 0)) begin
    repeat (30) @(posedge itf.clk);
    $display("TOP: Errcode: %0d", itf.errcode);
    $finish;
end

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (itf.halt)
    begin
        //$display("-here");
        $finish;
    end
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
    // write to tiles
	if (regfile_load & regfile_addr)
    begin
		$fwrite(f,"-PC is %x, input to regfile is %x, address is %d\n",PC_out,regfile_in,regfile_addr);
        $fwrite(g,"Time (regfile commit) in ns is %d\n",$time);
    end
    if( (State == ldr1) & mem_resp)
    begin
        $fwrite(f,"On load, PC is %x, mem_address is %x, read data is %x, dest reg address is %d\n", PC_out, mem_address, mem_rdata, rd);
        $fwrite(g,"Time (load) in ns is %d\n",$time);
    end
    if( (State == str1) & mem_resp)
    begin
        $fwrite(f,"On store, PC is %x, mem_address is %x, write data is %x, mbe is %b\n", PC_out, mem_address, mem_wdata, dut.mem_byte_enable);
        $fwrite(g,"Time (store) in ns is %d\n",$time);
    end


end

// Simulataneous Memory Read and Write
always @(posedge itf.clk iff (itf.mem_read && itf.mem_write))
    $error("@%0t TOP: Simultaneous memory read and write detected", $time);

/*****************************************************************************/

endmodule : mp2_tb
