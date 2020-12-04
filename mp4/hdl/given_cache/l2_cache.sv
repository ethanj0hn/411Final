// import cache_types::*;
// import rv32i_types::*;

module l2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
  input clk,
  input rst,
  /* Physical memory signals */
  input logic pmem_resp,
  input logic [255:0] pmem_rdata,
  output logic [31:0] pmem_address,
  output logic [255:0] pmem_wdata,
  output logic pmem_read,
  output logic pmem_write,

  /* CPU memory signals */
  input logic mem_read,
  input logic mem_write,
  input logic [31:0] mem_address,
  input logic [255:0] mem_wdata,
  output logic mem_resp,
  output logic [255:0] mem_rdata
);

// logic tag_load;
// logic valid_load;
// logic dirty_load;
// logic dirty_in;
// logic dirty_out;

// logic hit;
// logic [1:0] writing;


logic [31:0] mem_byte_enable;
assign mem_byte_enable = 32'hFFFFFFFF;

// cache_control control(.*);
// cache_datapath datapath(.*);

logic reset;
assign reset = rst;

logic WE0; // Write Enable from CPU
logic WE1;
logic ld_dirty0; // set dirty; valid; and clear dirty bits
logic ld_dirty1;
logic ld_valid0;
logic ld_valid1;
logic clear_dirty0; // clears dirty bit on update state
logic clear_dirty1;
logic mem_b_sel; // mem byte enable select
logic eviction_addr_sel; // which way should be evicted
logic mem_addr_sel; // eviction address or CPU address?
logic load_lru; // flips lru bit on a read/write; also used to load valid
logic [31:0] mem_byte_enable256; // mem_byte enable from bus adaptor/CPU
logic [255:0] mem_wdata256; // write data from adaptor
logic [31:0] pmem_addr; // 256 bit aligned address when reading from memory
logic [s_line - 1:0] mem_rdata256; // data to data bus->CPU
logic hit0; // hits on either of the ways
logic hit1;
logic dirty_eviction; // is eviction going to be dirty?
logic LRU; // LRU bit to send to control

l2cache_control control
(
    .*
);

l2cache_datapath datapath
(
    .*
);

endmodule : l2_cache
