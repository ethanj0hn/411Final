module tag_array(
    input logic clk,
    input logic reset,
    input logic load,
    input logic [2:0] addr,
    input logic [23:0] tag_in,
    output logic hit,
    output logic [23:0] rtag
);

logic [23:0] data [7:0];

always_ff @(posedge clk)
begin
    if (reset)
    begin
        for (int i=0; i<8; i++)
            data[i] <= 24'h0;
    end
    else if (load)
        data[addr] <= tag_in;
end

assign hit = (data[addr] == tag_in);
assign rtag = data[addr];

endmodule : tag_array

// module for selecting data to cache regs to write on a miss.
// if it is a read, we just pass the data straight through, if not, assign appropriate data
//
module write_mux(
    input logic select, // read or write from CPU?
    input logic [255:0] from_mem, // data read from memory
    input logic [255:0] from_adapter, // write data from CPU
    input logic [31:0] mem_byte_enable, // 32 bit mem_b_enable
    output logic [255:0] data_to_reg
);

always_comb
begin
    if(!select)
        data_to_reg = from_mem;
    else
    begin
        for(int i = 0; i< 32; i++)
        begin
            if(mem_byte_enable[i])
                data_to_reg[8*i +: 8] = from_adapter[8*i +: 8];
            else
                data_to_reg[8*i +: 8] = from_mem[8*i +: 8];
        end
    end
end


endmodule : write_mux

// module cache_regs(
//     input logic select, // read or write from CPU?
//     input logic [255:0] from_mem, // data read from memory
//     input logic [255:0] from_adaptor, // write data from CPU
//     input logic [31:0] mem_byte_enable, // 32 bit mem_b_enable
//     output logic [255:0] data_to_reg
// );

// write_mux wm(.*);

// endmodule : cache_regs