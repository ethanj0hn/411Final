#  test_alu.s version 4.0
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
    addi x1, x0, 5  # setting initial values (addi must work for this)
    addi x7, x0, 7
    addi x9, x0, 9
    addi x15, x0, -5
    addi x16, x0, 1
    nop
    nop
    nop
    nop
    nop
    add x2, x0, x1 # testing reg reg instructions
    sub x3, x0, x1
    xor x4, x1, x7
    or x5, x1, x9
    and x6, x1, x9
    slt x8, x15, x1
    sltu x10, x15, x1
    sll x11, x7, x16
    srl x12, x7, x16
    sra x13, x7, x16
    nop
    nop
    nop
    nop
HALT:
    beq x0, x0, HALT
    nop
    nop
    nop
    nop