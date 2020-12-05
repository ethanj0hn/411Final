/*
Control for eviction write buffer
*/
import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module ewb_control(
    input logic clk,
    input logic reset,
    input logic mem_read,
    input logic mem_write,
    input logic pmem_resp,
    input logic [31:0] mem_address_from_cache,
    input logic [31:0] mem_address_ewb,
    output logic pmem_read,
    output logic pmem_write,
    output logic mem_resp_to_cache,
    output logic allow_buff_load,
    output logic [31:0] pmem_address
);

// States from design
//
ewb_states State, Next_state;

always_comb
begin
    unique case (State)
        start:
        begin
            mem_resp_to_cache = pmem_resp;
            pmem_read = mem_read;
            pmem_write = 1'b0;
            allow_buff_load = 1'b1;
            pmem_address = mem_address_from_cache;
            
            if (mem_write)
                Next_state = mem_resp;
            else
                Next_state = start;
        end

        mem_resp:
        begin
            mem_resp_to_cache = 1'b1;
            pmem_read = 1'b0;
            pmem_write = 1'b0;
            allow_buff_load = 1'b0;
            pmem_address = mem_address_from_cache;


            Next_state = wait_;
        end

        wait_:
        begin
            mem_resp_to_cache = pmem_resp;
            pmem_read = mem_read;
            pmem_write = 1'b0;
            allow_buff_load = 1'b0;
            pmem_address = mem_address_from_cache;

            if (pmem_resp)
                Next_state = process_dirty_eviction;
            else
                Next_state = wait_;            
        end

        process_dirty_eviction:
        begin
            mem_resp_to_cache = 1'b0;
            pmem_read = 1'b0;
            pmem_write = 1'b1;
            allow_buff_load = 1'b0;
            pmem_address = mem_address_ewb;

            if (pmem_resp)
                Next_state = start;
            else
                Next_state = process_dirty_eviction;
        end

    endcase

end

always_ff @(posedge clk)
begin
    if (reset)
        State <= start;
    else
        State <= Next_state;
end

endmodule : ewb_control
