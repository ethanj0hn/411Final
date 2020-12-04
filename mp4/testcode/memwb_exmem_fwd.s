memwb_exmem_fwd.s:
.align 4
.section .text
.globl _start

_start:
    la x3, TEST
    addi x5, x0, 10
    sw x5, (x3)
    lw x7, (x3)

halt:
    beq x0,x0,halt
    nop
    nop

.section .rodata
.balign 256
TEST: .word 0x00000000