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


cacheline_adaptor ca (
    .clk(clk),
    .reset_n(~reset),

    // Port to arbiter
    .line_i(ab_pmem_wdata),
    .line_o(ab_pmem_rdata),
    .address_i(ab_pmem_address),
    .read_i(ab_pmem_read),
    .write_i(ab_pmem_write),
    .resp_o(ab_pmem_resp),

    // Port to memory
    .burst_i(mem_rdata),
    .burst_o(mem_wdata),
    .address_o(mem_addr),
    .read_o(mem_read),
    .write_o(mem_write),
    .resp_i(mem_resp)
);

// arbiter if else block
always_comb
begin
    if (i_pmem_read) begin

        // inputs
        ab_pmem_read = i_pmem_read;
        ab_pmem_write = i_pmem_write;
        ab_pmem_address = i_pmem_address;
        ab_pmem_wdata = i_pmem_wdata;
        
        // outputs to icache
        i_pmem_rdata = ab_pmem_rdata;
        i_pmem_resp = ab_pmem_resp;
        
        // outputs to dcache
        d_pmem_rdata = 256'b0;
        d_pmem_resp = 1'b0;
    end
    else begin

        // inputs
        ab_pmem_read = d_pmem_read;
        ab_pmem_write = d_pmem_write;
        ab_pmem_address = d_pmem_address;
        ab_pmem_wdata = d_pmem_wdata;

        // outputs to dcache
        d_pmem_rdata = ab_pmem_rdata;
        d_pmem_resp = ab_pmem_resp;

        // outputs to icache
        i_pmem_rdata = 256'b0;
        i_pmem_resp = 1'b0;
    end
end

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
