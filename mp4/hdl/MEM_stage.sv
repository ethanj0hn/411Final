import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module MEM_stage(
    input clk,
    input rst,
    input rv32i_control_word ctrl,

    // from current IR
    input [2:0] funct3_mem,

    // from exec
    input [31:0] rs2_out,
    input [31:0] alu_buffered, // calculated address
    input [2:0] funct3_exec,

    // to wb
    output logic [31:0] data_value, // data from data_value_register
    output logic [2:0] mem_address_last_two_bits

    // interfacing cache / memory
    input [31:0] mem_rdata,
    output logic [31:0] mem_wdata,
    output logic [31:0] mem_address,
    output logic [4:0] mem_byte_enable,
    output logic data_read,
    output logic data_write
);

// local signals
logic load_data_address;
logic load_data_out;
logic load_data_value;
assign load_data_address = ctrl.load_data_address;
assign load_data_out = ctrl.load_data_address;
assign load_data_value = ctrl.load_data_value;
assign data_read = ctrl.data_read;
assign data_write = ctrl.data_write;

// local data
logic [31:0] mem_address_raw;
logic [31:0] data_to_store;
assign mem_address = {mem_address_raw[31:2], 2'b00};
assign mem_address_last_two_bits = mem_address_raw[1:0];

// muxes
always_comb
begin
    // data to store mux
    // this value is loaded into mem_data_out during
    // exec, so it uses alu_buffered
    // and exec's funct3 as the mux select
    case (store_funct3_t'(funct3_exec))
        sw: data_to_store = rs2_out;
        sh: 
        begin
            case (alu_buffered[1:0])
                2'b00, 2'b01 : data_to_store = {16'b0, rs2_out[15:0]};
                2'b10, 2'b11 : data_to_store = {rs2_out[15:0], 16'b0};
                default: data_to_store = rs2_out;
            endcase
        end
        sb:
        begin
            case (alu_buffered[1:0])
                2'b00 : data_to_store = {24'b0, rs2_out[7:0]};
                2'b01 : data_to_store = {16'b0, rs2_out[7:0], 8'b0};
                2'b10 : data_to_store = {8'b0, rs2_out[7:0], 16'b0};
                2'b11 : data_to_store = {rs2_out[7:0], 24'b0};
                default : data_to_store = rs2_out;
            endcase
        end
        default: data_to_store = rs2_out;
    endcase

    // mem_byte_enable mux
    // this value is loaded during mem stage, so 
    // it uses mem's funct3 and mem_address_raw as mux sel
    case (store_funct3_t'(funct3_mem))
        sw: mem_byte_enable = 4'b1111;
        sh:
        begin
            unique case(mem_address_last_two_bits)
                default: mem_byte_enable = 4'b1111;
                2'b00, 2'b01: mem_byte_enable = 4'b0011;
                2'b10, 2'b11: mem_byte_enable = 4'b1100;
            endcase
        end
        sb:
        begin
            unique case(mem_address_last_two_bits)
                default: mem_byte_enable = 4'b1111;
                2'b00: mem_byte_enable = 4'b0001;
                2'b01: mem_byte_enable = 4'b0010;
                2'b10: mem_byte_enable = 4'b0100;
                2'b11: mem_byte_enable = 4'b1000;
            endcase
        end
        default: mem_byte_enable = 4'b1111;
    endcase
end 

register data_address_register(
    .clk(clk),
    .rst(rst),
    .load(load_data_address),
    .in(alu_result),
    .out(mem_address_raw)
);

register mem_data_out(
    .clk(clk),
    .rst(rst),
    .load(load_data_out),
    .in(data_to_store),
    .out(mem_wdata)  
);

register data_value_register(
    .clk  (clk),
    .rst (rst),
    .load (load_data_value),
    .in   (mem_rdata),
    .out  (data_value)
);



endmodule : MEM_stage