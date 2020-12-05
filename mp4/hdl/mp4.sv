module mp4(
    input logic clk,
    input logic reset,
    input logic mem_resp,
    input logic [63:0] mem_rdata,
    output logic mem_read,
    output logic [31:0] mem_addr,
    output logic [63:0] mem_wdata,
    output logic mem_write
);

// signals from l2 cache
logic l2_pmem_resp;
logic [255:0] l2_pmem_rdata;
logic [31:0] l2_pmem_address;
logic [255:0] l2_pmem_wdata;
logic l2_pmem_read;
logic l2_pmem_write;

// signals from arbiter
logic ab_pmem_resp;
logic [255:0] ab_pmem_rdata;
logic [31:0] ab_pmem_address;
logic [255:0] ab_pmem_wdata;
logic ab_pmem_read;
logic ab_pmem_write;

// signals from icache
logic i_pmem_resp;
logic [255:0] i_pmem_rdata;
logic [31:0] i_pmem_address;
logic [255:0] i_pmem_wdata;
logic i_pmem_read;
logic i_pmem_write;

// signals from dcache
logic d_pmem_resp;
logic [255:0] d_pmem_rdata;
logic [31:0] d_pmem_address;
logic [255:0] d_pmem_wdata;
logic d_pmem_read;
logic d_pmem_write;

// signals from datapath
logic data_resp; // response from data, instruction memory
logic inst_resp;
logic [31:0] inst_rdata; // instruction, data read port
logic [31:0] data_rdata;
logic inst_read; // instruction port address, read signal
logic [31:0] inst_addr;
logic data_read; // data read write signals
logic data_write; 
logic [3:0] data_mbe; // mem_byte_enable, signals data port address
logic [31:0] data_addr; 
logic [31:0] data_wdata;

// prefetching signals
logic inst_present;


cacheline_adaptor ca (
    .clk(clk),
    .reset_n(~reset),

    // Port to l2 cache
    .line_i(l2_pmem_wdata),
    .line_o(l2_pmem_rdata),
    .address_i(l2_pmem_address),
    .read_i(l2_pmem_read),
    .write_i(l2_pmem_write),
    .resp_o(l2_pmem_resp),

    // Port to memory
    .burst_i(mem_rdata),
    .burst_o(mem_wdata),
    .address_o(mem_addr),
    .read_o(mem_read),
    .write_o(mem_write),
    .resp_i(mem_resp)
);

l2_cache level_two_cache (
    .clk(clk),
    .rst(reset),

    /* Prefetching signals */
    .inst_addr(inst_addr),
    .inst_present(inst_present),

    /* Physical memory signals */
    .pmem_resp(l2_pmem_resp),
    .pmem_rdata(l2_pmem_rdata),
    .pmem_address(l2_pmem_address),
    .pmem_wdata(l2_pmem_wdata),
    .pmem_read(l2_pmem_read),
    .pmem_write(l2_pmem_write),

    /* Arbiter signals */
    .mem_read(ab_pmem_read),
    .mem_write(ab_pmem_write),
    .mem_address(ab_pmem_address),
    .mem_wdata(ab_pmem_wdata),
    .mem_resp(ab_pmem_resp),
    .mem_rdata(ab_pmem_rdata)
);

arbiter arb(.*);

cache i_cache (
  .clk(clk),

  /* Physical memory signals */
  .pmem_resp(i_pmem_resp),
  .pmem_rdata(i_pmem_rdata),
  .pmem_address(i_pmem_address),
  .pmem_wdata(i_pmem_wdata),
  .pmem_read(i_pmem_read),
  .pmem_write(i_pmem_write),

  /* CPU memory signals */
  .mem_read(inst_read),
  .mem_write(1'b0), // instruction cache does not write
  .mem_byte_enable_cpu(4'b0), // instruction cache does not write
  .mem_address(inst_addr),
  .mem_wdata_cpu(32'b0), // instruction cache does not write
  .mem_resp(inst_resp),
  .mem_rdata_cpu(inst_rdata)
);

cache d_cache (
  .clk(clk),

  /* Physical memory signals */
  .pmem_resp(d_pmem_resp),
  .pmem_rdata(d_pmem_rdata),
  .pmem_address(d_pmem_address),
  .pmem_wdata(d_pmem_wdata),
  .pmem_read(d_pmem_read),
  .pmem_write(d_pmem_write),

  /* CPU memory signals */
  .mem_read(data_read),
  .mem_write(data_write),
  .mem_byte_enable_cpu(data_mbe),
  .mem_address(data_addr),
  .mem_wdata_cpu(data_wdata),
  .mem_resp(data_resp),
  .mem_rdata_cpu(data_rdata)
);

pipeline_datapath datapath(.*);

endmodule : mp4
