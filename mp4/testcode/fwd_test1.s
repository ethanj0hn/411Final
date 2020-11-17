fwd_test.s:
.align 4
.section .text
.globl _start
# if test works, see 4 in x1
_start:
    addi x1,x0,1 # x1 <- 1
    # add x1,x1,x1 # x1 <- 2
    add x1,x1,x1 # x1 <- 4
    nop
    nop
    nop
    nop
    nop
halt:
    beq x0,x0,halt
    nop
    nop
    nop
    nop
