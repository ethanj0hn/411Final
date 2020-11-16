load_test.s:
.align 4
.section .text
.globl _start
# if test works, see 1 in x1, 0 in x2 otherwise 0 in x1, 2 in x2
_start:
    addi x1,x0,1
    nop
    nop
    nop
    nop
    nop
    nop
    beq x0,x0,halt
    and x1,x1,x1
    addi x2,x0,2
    addi x2,x2,1
    addi x2,x2,1
    nop
    nop
    nop
halt:
    beq x0,x0,halt
    nop
    nop
    nop
    nop
    nop
    nop

bad:        .word 0xdeadbeef
good:       .word 0x600d600d