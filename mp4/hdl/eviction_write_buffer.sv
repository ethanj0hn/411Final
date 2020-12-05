module eviction_write_buffer(
    // from cache
    input logic clk,
    input logic reset,
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] mem_address,
    input logic [255:0] mem_wdata,
    // from memory
    input logic [255:0] pmem_rdata,
    input logic pmem_resp,
    // to cache
    output logic mem_resp,
    output logic [255:0] mem_rdata,
    // to memory
    output logic pmem_read,
    output logic pmem_write,
    output logic [255:0] pmem_wdata,
    output logic [31:0] pmem_address
);

logic allow_buff_load;
logic [31:0] mem_address_ewb;
logic [255:0] write_buffer;

// only loads in the start state
//
always_ff @(posedge clk)
begin
    if (reset)
    begin
        write_buffer <= 256'h0;
        mem_address_ewb <= 32'h0;
    end
    else if (allow_buff_load & mem_write)
    begin
        write_buffer <= mem_wdata;
        mem_address_ewb <= mem_address;
    end
    else
    begin
        write_buffer <= write_buffer;
        mem_address_ewb <= mem_address_ewb;
    end
end

assign pmem_wdata = write_buffer;
assign mem_rdata = pmem_rdata;

ewb_control control(
    .clk(clk),
    .reset(reset),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .pmem_resp(pmem_resp),
    .mem_address_from_cache(mem_address),
    .mem_address_ewb(mem_address_ewb),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .mem_resp_to_cache(mem_resp),
    .allow_buff_load(allow_buff_load),
    .pmem_address(pmem_address)
);

endmodule : eviction_write_buffer