/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module l2_cache_control (
    input logic clk,
    input logic reset,
    input logic mem_read, // mem_read from CPU
    input logic mem_write, // mem_write from CPU
    input logic dirty_eviction, // boolean logic set on a dirty eviction from cache datapath/regs
    input logic LRU, // LRU bit from cache datapath
    input logic hit0, // boolean logic for hit in cache on ways 0, 1 
    input logic hit1, 
    input logic pmem_resp, // response from physical memory
    output logic eviction_addr_sel, // MUX select for which address to evict based on LRU
    output logic mem_resp, // mem_resp to CPU
    output logic mem_addr_sel, // memory address select for CPU addr vs eviction addr
    output logic pmem_read,
    output logic pmem_write, // read and write signals to memory
    output logic WE0, // write signals to cache regs
    output logic WE1,
    output logic load_lru, // flip LRU signal on reads/writes
    output logic mem_b_sel, // mem bye enable select
    output logic clear_dirty0, // clears dirty bit on dirty eviction
    output logic clear_dirty1,
    output logic ld_dirty0, // load dirty bits on ways 0, 1
    output logic ld_dirty1,
    output logic ld_valid0, // load valids on ways 0, 1
    output logic ld_valid1
);

enum logic [2:0] {
    Start,
    Miss,
    Update,
    Load_cache,
    Resp
} State, Next_state;

// hit from old design
logic hit;
assign hit = hit0|hit1; // is there a hit?

always_comb
begin
    Next_state = State;

    mem_resp = 1'b0;
    mem_addr_sel = 1'b0;
    WE0 = 1'b0; // on a hit in the cache and a write operation, write to the cache registers
    WE1 = 1'b0;
    pmem_write = 1'b0; // read and write to physical memory defualt 0
    pmem_read = 1'b0;
    eviction_addr_sel = LRU; // default eviction always LRU
    load_lru = 1'b0; // don't load on default
    mem_b_sel = 1'b0; // default take CPU's memb enable
    clear_dirty0 = 1'b0; // don't clear,load dirty/valid bit on default
    clear_dirty1 = 1'b0;
    ld_dirty0 = 1'b0;
    ld_dirty1 = 1'b0;
    ld_valid0 = 1'b0;
    ld_valid1 = 1'b0;

    case (State)

    Start:
        begin
            load_lru = hit; // on a hit, flip LRU bit to ensure it is ready by 2 cycles.
            if (hit0 & mem_write) // on hit and write, set dirty bit
            begin
                WE0 = 1'b1;  // on a hit on way0/1 and write, write to way 0/1, set appropriate dirty bit
                ld_dirty0 = 1'b1;
            end
            else if (hit1 & mem_write)
            begin
                ld_dirty1 = 1'b1;
                WE1 = 1'b1;
            end

            if((mem_read|mem_write) & hit)
                Next_state = Resp;
            else if ((mem_read|mem_write) & !hit)
                Next_state = Miss;
        end

    Resp:
        begin
            mem_resp = 1'b1; // raise mem_resp high

            Next_state = Start;
        end  

    Miss:
        begin
            pmem_read = 1'b1; // read from memory on miss, disable writes

            if(!pmem_resp) // wait for mem response
                Next_state = Miss;
            else if (dirty_eviction & pmem_resp) // if dirty eviciton, flush to memory first
                Next_state = Update;
            else if (pmem_resp & !dirty_eviction)
                Next_state = Load_cache; // else just write to cache reg file
        end  

    Update:
        begin
            pmem_write = 1'b1; // write to memory, disable writes to cache regfile
            eviction_addr_sel = LRU;// evict LRU entry
            mem_addr_sel = 1'b1; //  select address to memory as eviction address
            if (!LRU)
            begin
                clear_dirty0 = 1'b1;
                ld_dirty0 = 1'b1;
            end
            else
            begin
                clear_dirty1 = 1'b1;
                ld_dirty1 = 1'b1;
            end
            // while no memory response, stay in state
            // otherwise go to load cache
            if (!pmem_resp)
                Next_state = Update;
            else if (pmem_resp)
                Next_state = Load_cache;
        end

    Load_cache:
        begin
            load_lru = 1'b1; // set LRU bit
            mem_b_sel = 1'b1; // select to load 256 bit entry
            
            if (!LRU)
            begin
                ld_valid0 = 1'b1;
                WE0 = 1'b1; // write to cache regs appropriate way 
                if(mem_write) // based on LRU, set appropriate valid and dirty bit writes if required.
                    ld_dirty0 = 1'b1;
            end
            else if (LRU)
            begin
                ld_valid1 = 1'b1;
                WE1 = 1'b1;
                if(mem_write) // based on LRU, set appropriate valid and dirty bit writes if required.
                    ld_dirty1 = 1'b1;
            end

            Next_state = Resp; // go to resp state after loading cache regs
        end



    endcase

end

// state assignment
//
always_ff @(posedge clk)
begin
    if (reset)
        State <= Start;
    else
        State <= Next_state;
end

endmodule : l2_cache_control
