#  reg_br_mem.s version 4.0
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
    nop
    la x2, ONE # test basic load / store, modify for half / bytes signed and unsigned
    nop
    nop
    nop
    nop
    nop
    sw x1, (x2)
    nop
    nop
    nop
    nop
    nop
    lw x3, (x2)
    nop
    nop
    nop
    nop
    nop
    bne x7, x9, HALT # replace with desired br operation
    addi x18, x0, 5
HALT:
    beq x0, x0, HALT

.section .rodata
.balign 256
ONE:    .word 0x00000001
TWO:    .word 0x00000002
NEGTWO: .word 0xFFFFFFFE
TEMP1:  .word 0x00000001
GOOD:   .word 0x600D600D
BADD:   .word 0xBADDBADD
BYTES:  .word 0x04030201
HALF:   .word 0x0020FFFF