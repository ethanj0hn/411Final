.align 4
.section .text
.globl _start
_start:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    jal x1, ld_reg
    nop
    nop
ld_reg:
    lw x5, testval
    jalr x2, 3(x1)    
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    addi x1, x0, 5 
    addi x7, x0, 7
    addi x9, x0, 9
    addi x15, x0, -5
    addi x16, x0, 1
    addi x20, x0, 15
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    slti x1, x0, 1
    andi x3, x7, 7
    xori x8, x9, 8
    ori x6, x0, 1
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    auipc x7, 8         # X7 <= PC + 8
    lui  x2, 2       # X2 <= 2
    lui  x3, 8     # X3 <= 8
    nop
    nop
    nop
    nop
    nop
    nop
HALT:
    beq x0, x0, HALT






.section .rodata
.balign 256
testval:    .word 0x0000B00B
