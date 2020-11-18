module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

enum logic [1:0] {READY, BURST_R, BURST_W, FINISHED} curr_state, next_state;

logic [2:0] curr_counter, next_counter;

always_ff @(posedge clk)
begin
    if(reset_n)
        begin
            curr_state <= next_state;
            curr_counter <= next_counter;
        end
    else
        begin
            curr_state <= READY;
            curr_counter <= 3'b000;
        end   
end

always_ff @(posedge clk)
begin
    if (resp_i == 1'b1 && read_o == 1'b1)
    begin
        line_o[64*curr_counter +: 64] <= burst_i;
    end
end

always_comb
    begin
        next_state = curr_state;
        next_counter = curr_counter;
        address_o = address_i;
        // resp_o = resp_i;
        resp_o = 1'b0;
        read_o = 1'b0;
        write_o = 1'b0;
        burst_o = line_i[64*curr_counter +: 64];
        unique case (curr_state)
            READY:
                begin
                    next_counter = 3'b000;
                    if (write_i == 1'b1)
                        next_state = BURST_W;
                    if (read_i == 1'b1)
                        next_state = BURST_R;
                end
            BURST_R:
                begin
                    read_o = 1'b1;
                    if (resp_i == 1'b1)
                    begin
                        if (curr_counter == 3'b011)
                            begin
                                // resp_o = 1'b1;
                                next_state = FINISHED;
                            end
                        else
                            next_counter = curr_counter + 3'b001;
                    end
                end
            BURST_W:
                begin
                    write_o = 1'b1;
                    if (resp_i == 1'b1)
                    begin
                        if (curr_counter == 3'b011)
                            next_state = FINISHED;
                        else
                            next_counter = curr_counter + 3'b001;
                    end
                end
            FINISHED:
                begin
                    resp_o = 1'b1;
                    next_state = READY;
                end
            default: ;
        endcase
    end
endmodule : cacheline_adaptor
