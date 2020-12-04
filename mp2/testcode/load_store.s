load_store.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.
    # addi x11,x0,0x069
    la x3,bad

    lh x1,(x3)
    lh x1,2(x3)

    lw x1, (x3)

    la x3,answer

    sw x1, (x3)

    # add x1,x3,x1 
    slt x1,x3,x1
    sltu x1,x3,x1
    sub x1,x3,x1
    sra x1,x3,x1

    jal x1,sumanth

back:

    # lhu x2,(x3)
    # lhu x2,2(x3)

    # lb x4,(x3)
    # lb x4,1(x3)
    # lb x4,2(x3)
    # lb x4,3(x3)

    # lbu x5,(x3)
    # lbu x5,1(x3)
    # lbu x5,2(x3)
    # lbu x5,3(x3)
halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.

sumanth:
    la x2,back
    jalr x1,x2,0



bad:        .word 0xdeadbeef
storage:    .word 0x0456f3f0
good:       .word 0x600d600d
answer:     .word 0x600d600d
