import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    input logic clk,
    input logic rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic mem_resp, // memory response
    input logic [1:0] mem_addr_mask, // for byte/half reads/writes
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
    output logic mem_read, // mem_read and write output signals
    output logic mem_write,
    output branch_funct3_t cmpop,
    output logic [3:0] mem_byte_enable, // for specifying which bytes to write to
    output logic [3:0] rmask_o
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;
assign rmask_o = rmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lb, lbu:
                begin
                    unique case(mem_addr_mask)
                        2'b00: rmask = 4'b0001;
                        2'b01: rmask = 4'b0010;
                        2'b10: rmask = 4'b0100;
                        2'b11: rmask = 4'b1000;
                        default: rmask = 4'b1111;
                    endcase
                end

                lh, lhu:
                begin
                    unique case(mem_addr_mask)
                        2'b00,2'b01: rmask = 4'b0011;
                        2'b10,2'b11: rmask = 4'b1100;
                        default: rmask = 4'b1111;
                    endcase
                end
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh:
                begin
                    unique case(mem_addr_mask)
                        2'b00,2'b01: wmask = 4'b0011;
                        2'b10,2'b11: wmask = 4'b1100;
                        default: wmask = 4'b1111;
                    endcase
                end

                sb:
                begin
                    unique case(mem_addr_mask)
                        2'b00: wmask = 4'b0001;
                        2'b01: wmask = 4'b0010;
                        2'b10: wmask = 4'b0100;
                        2'b11: wmask = 4'b1000;
                        default: wmask = 4'b1111;
                    endcase
                end

                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
    fetch1,
    fetch2,
    fetch3,
    decode,
    s_imm_slti,
    s_imm_sltiu,
    s_imm_srai,
    s_imm_other,
    s_reg_slt,
    s_reg_sltu,
    s_reg_sra,
    s_reg_other,
    s_reg_sub,
    br,
    ldr1,
    ldr2,
    calc_addr_lw,
    calc_addr_sw,
    str1,
    str2,
    s_auipc,
    s_lui,
    jal,
    jalr
} State, Next_state;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
// function void set_defaults();
//     Next_state = State;
//     load_mar = 1'b0;
//     load_mdr = 1'b0;
//     mem_read = 1'b0;
//     load_ir = 1'b0;
//     load_regfile = 1'b0;
//     load_pc = 1'b0;
//     cmpop = beq;
//     regfilemux_sel = 2'b00;
//     cmpmux_sel = 1'b0;
//     rs1_addr = 5'b0;
//     rs2_addr = 5'b0;
//     alumux1_sel = 1'b0;
//     alumux2_sel = 2'b00;
//     marmux_sel = 1'b0;
//     mem_read = 1'b0;
//     mem_write = 1'b0;
// endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
// function void loadPC(pcmux::pcmux_sel_t sel);
//     load_pc = 1'b1;
//     pcmux_sel = sel;
// endfunction

// function void loadRegfile(regfilemux::regfilemux_sel_t sel);
// endfunction

// function void loadMAR(marmux::marmux_sel_t sel);
// endfunction

// function void loadMDR();
// endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
// function void setALU(alumux::alumux1_sel_t sel1,
//                                alumux::alumux2_sel_t sel2,
//                                logic setop = 1'b0, alu_ops op = alu_add);
//     /* Student code here */


//     if (setop)
//         aluop = op; // else default value
// endfunction

// function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
// endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    Next_state = State;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_pc = 1'b0;
    regfilemux_sel = regfilemux::alu_out; // 0
    cmpmux_sel = cmpmux::rs2_out; // 0
    alumux1_sel = alumux::rs1_out; // 0
    alumux2_sel = alumux::i_imm; // 0
    marmux_sel = marmux::pc_out; // 0
    mem_read = 1'b0;
    mem_write = 1'b0;
    aluop = alu_ops'(funct3); // 0
    pcmux_sel = pcmux::pc_plus4; // 0
    load_data_out = 1'b0;
    cmpop = branch_funct3;
    mem_byte_enable = 4'b1111;
    /* Actions for each state */
    case (State)
        fetch1:
        begin
           load_mar = 1'b1;
           Next_state = fetch2;
        end
        fetch2:
        begin
            if(mem_resp==1'b0)
                Next_state = fetch2;
            else
                Next_state = fetch3;
            load_mdr = 1'b1;
            mem_read = 1'b1;
        end
        fetch3:
        begin
            load_ir = 1'b1;
            Next_state = decode;
        end

        decode:
        begin // TODO: change later
            case (opcode)
                op_imm:
                begin
                    case (funct3)
                        3'b000: Next_state = s_imm_other;
                        3'b001: Next_state = s_imm_other;
                        3'b010: Next_state = s_imm_slti;
                        3'b011: Next_state = s_imm_sltiu;
                        3'b100: Next_state = s_imm_other;
                        3'b101:
                        begin
                            if(funct7 == 7'b0)
                                Next_state = s_imm_other;
                            else
                                Next_state = s_imm_srai;
                        end
                        3'b110:
                            Next_state = s_imm_other;
                        3'b111:
                            Next_state = s_imm_other;
                        default: Next_state = fetch1;
                    endcase
                end

                op_reg:
                begin
                    case (arith_funct3_t'(funct3))
                        add: 
                        begin
                            if(funct7 == 7'b0)
                                Next_state = s_reg_other;
                            else
                                Next_state = s_reg_sub;
                        end
                        sll: Next_state = s_reg_other;
                        slt: Next_state = s_reg_slt;
                        sltu: Next_state = s_reg_sltu;
                        axor: Next_state = s_reg_other;
                        sr:
                        begin
                            if(funct7 == 7'b0)
                                Next_state = s_reg_other;
                            else
                                Next_state = s_reg_sra;
                        end
                        aor:
                            Next_state = s_reg_other;
                        aand:
                            Next_state = s_reg_other;
                        default: Next_state = fetch1;
                    endcase 
                end
                op_br:
                    Next_state = br;

                op_load:
                    Next_state = calc_addr_lw;

                op_store:
                    Next_state = calc_addr_sw;

                op_lui:
                    Next_state = s_lui;
                
                op_auipc:
                    Next_state = s_auipc;
                
                op_jal:
                    Next_state = jal;
                
                op_jalr:
                    Next_state = jalr;

                default:
                    Next_state = fetch1;

            endcase
        end

        s_imm_slti:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            cmpop = blt;
            regfilemux_sel = regfilemux::br_en; // 1
            cmpmux_sel = cmpmux::i_imm; // 1

            Next_state = fetch1;
        end

        s_reg_slt:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            cmpop = blt;
            regfilemux_sel = regfilemux::br_en; // 1

            Next_state = fetch1;
        end

        s_imm_sltiu:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            cmpop = bltu;
            regfilemux_sel = regfilemux::br_en; // 1
            cmpmux_sel = cmpmux::i_imm; //1 

            Next_state = fetch1;
        end

        s_reg_sltu:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            cmpop = bltu;
            regfilemux_sel = regfilemux::br_en; // 1

            Next_state = fetch1;
        end

        s_imm_srai:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_sra;

            Next_state = fetch1;
        end

        s_reg_sra:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_sra;
            alumux2_sel = alumux::rs2_out;

            Next_state = fetch1;
        end

        s_imm_other:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_ops'(funct3);

            Next_state = fetch1;
        end

        s_reg_other:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_ops'(funct3);
            alumux2_sel = alumux::rs2_out;

            Next_state = fetch1;
        end

        s_reg_sub:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_sub;
            alumux2_sel = alumux::rs2_out;

            Next_state = fetch1;
        end

        br:
        begin
            pcmux_sel = pcmux::pcmux_sel_t'({1'b0,br_en});
            load_pc = 1'b1;
            alumux1_sel = alumux::pc_out; // 1
            alumux2_sel = alumux::b_imm; // 2
            aluop = alu_add;

            Next_state = fetch1;
        end

        calc_addr_lw:
        begin
            aluop = alu_add;
            load_mar = 1'b1;
            marmux_sel = marmux::alu_out; // 1

            Next_state = ldr1;
        end
        
        ldr1:
        begin
            load_mdr = 1'b1;
            mem_read = 1'b1;
            if(mem_resp)
                Next_state = ldr2;
            else
                Next_state = ldr1;
        end

        ldr2:
        begin

            case (load_funct3)
            lw : regfilemux_sel = regfilemux::lw; // 3;
            lb: regfilemux_sel = regfilemux::lb;
            lbu: regfilemux_sel = regfilemux::lbu;
            lh: regfilemux_sel = regfilemux::lh;
            lhu: regfilemux_sel = regfilemux::lhu;
            default: regfilemux_sel = regfilemux::alu_out;

            endcase

            load_regfile = 1'b1;
            load_pc = 1'b1;

            Next_state = fetch1;
        end

        calc_addr_sw:
        begin
            alumux2_sel = alumux::s_imm; // 3
            aluop = alu_add;
            load_mar = 1'b1;
            load_data_out = 1'b1;
            marmux_sel = marmux::alu_out; // 1

            Next_state = str1;
        end

        str1:
        begin
            if(mem_resp)
                Next_state = str2;
            else
                Next_state = str1;

            case (store_funct3)
                sw: mem_byte_enable = 4'b1111;
                sh:
                begin
                    unique case(mem_addr_mask)
                        default: mem_byte_enable = 4'b1111;
                        2'b00, 2'b01: mem_byte_enable = 4'b0011;
                        2'b10, 2'b11: mem_byte_enable = 4'b1100;
                    endcase
                end
                sb:
                begin
                    unique case(mem_addr_mask)
                        default: mem_byte_enable = 4'b1111;
                        2'b00: mem_byte_enable = 4'b0001;
                        2'b01: mem_byte_enable = 4'b0010;
                        2'b10: mem_byte_enable = 4'b0100;
                        2'b11: mem_byte_enable = 4'b1000;
                    endcase
                end
            endcase
            
            mem_write = 1'b1;
        end

        str2:
        begin
            load_pc = 1'b1;

            Next_state = fetch1; 
        end

        s_auipc:
        begin
            alumux1_sel = alumux::pc_out; // 1
            alumux2_sel = alumux::u_imm; // 1
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_add;

            Next_state = fetch1;    
        end

        s_lui:
        begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            regfilemux_sel = regfilemux::u_imm;

            Next_state = fetch1;
        end

        jal:
        begin
            regfilemux_sel = regfilemux::pc_plus4;
            alumux1_sel = alumux::pc_out;
            alumux2_sel = alumux::j_imm;
            pcmux_sel = pcmux::alu_out;
            load_pc = 1'b1;
            load_regfile = 1'b1;
            aluop = alu_add;

            Next_state = fetch1;
        end

        jalr:
        begin
            regfilemux_sel = regfilemux::pc_plus4;
            pcmux_sel = pcmux::alu_mod2;
            load_pc = 1'b1;
            load_regfile = 1'b1;
            aluop = alu_add;

            Next_state = fetch1;
        end
           
        default:
            Next_state = fetch1;

    endcase
end

// always_comb
// begin : next_state_logic
//     /* Next state information and conditions (if any)
//      * for transitioning between states */
// end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if(rst)
        State = fetch1;
    else
        State = Next_state;

end

endmodule : control
