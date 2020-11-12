#  load_test.s version 4.0
.align 4
.section .text
.globl _start
_start:
pcrel_NEGTWO: auipc x10, %pcrel_hi(NEGTWO)
pcrel_TWO: auipc x11, %pcrel_hi(TWO)
pcrel_ONE: auipc x12, %pcrel_hi(ONE)
pcrel_GOOD: auipc x13, %pcrel_hi(GOOD)
pcrel_BADD: auipc x14, %pcrel_hi(BADD)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lw x1, %pcrel_lo(pcrel_NEGTWO)(x10) # 1 ??
    lw x2, %pcrel_lo(pcrel_TWO)(x11) # -2
    lw x3, %pcrel_lo(pcrel_ONE)(x12) # 2
    lw x4, %pcrel_lo(pcrel_GOOD)(x13) # baddbadd
    lw x5, %pcrel_lo(pcrel_BADD)(x14)
    nop
    nop
    nop
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
    nop
    nop
    nop

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