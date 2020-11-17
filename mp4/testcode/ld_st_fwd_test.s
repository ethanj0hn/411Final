ld_st_fwd_test.s:
.align 4
.section .text
.globl _start
# loads M[good] into x2, stores into address of bad
_start:
    la x3,good
    la x4,bad
    lw x2,(x3)
    sw x2,(x4)
halt:
    beq x0,x0,halt
    nop

bad:        .word 0xdeadbeef
good:       .word 0x600d600d