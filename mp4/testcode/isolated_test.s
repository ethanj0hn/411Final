.align 4
.section .text
.globl MoneyMoney


MoneyMoney:

    andi x7, x7, 0
    andi x6, x6, 0
    andi x5, x5, 0
    andi x4, x4, 0
    andi x3, x3, 0
    andi x2, x2, 0
    andi x1, x1, 0
    andi x8, x8, 0

    # addi x10, x0, 2660
    addi x10, x0, 2000
    addi x10, x10, 660

    # addi x15, x0, 2504
    addi x15, x0, 2000
    addi x15, x15, 504

    addi x16, x0, 1636

    addi x17, x0, 1688

    la x1, M00
    lw x2, Counter2
    lw x3, TWOFIVESIX
FillM1:
    sw x2, 0(x1)
    addi x2, x2, -7
    addi x1, x1, 4
    addi x3, x3, -1
    blt x0, x3, FillM1

    la x4, M00
    lw x2, TWOFIVESIX
    add x4, x2, x4
    lw x3, Counter2
    andi x1, x1, 0
    andi x2, x2, 0



FILLM2:
    jal x7,  CalAddress
    add x6, x5, x4
    sw  x3, 0(x6)
    addi x3, x3, -2
    jal x7,  CalNEXT2
    addi x5, x1, 0
    ble x0, x5, FILLM2

    la x4,  M00
    lw x2, TWOFIVESIX
    add x4, x2, x4
    add x4, x2, x4
    lw x3, Counter2
    andi x1, x1, 0
    andi x2, x2, 0



FILLM3:
    jal x7,  CalAddress
    add x6, x5, x4
    sw  x3, 0(x6)
    addi x3, x3, -5
    jal x7,  CalNEXT3
    addi x5, x1, 0
    ble x0, x5, FILLM3

    la x3, M00
    lw x4, TWOFIVESIX
    add x4, x3, x4
    andi x6, x6, 0





Continue1_2:

    lw x1, X2
    lw x2, Y2
    jal x7,  CalAddress
    add x7, x5, x4
    lw x6, 0(x7)
    jal x7,  CalNEXT3
    sw x1, X2, x15
    sw x2, Y2, x15
    
    lw x1, XX1
    lw x2, Y1
    jal x7,  CalAddress
    add x5, x5, x3
    lw x7, 0(x5)
    add x6, x6, x7
    sw x6, 0(x5)
    
    jal x7,  CalNEXT2
    addi x7, x1, 0
    bgt x0, x7, Done3
    sw x1, XX1, x15
    sw x2, Y1, x15
    
    beq x0, x0, Continue1_2
Done3:

    andi x1, x1, 0
    sw  x1, XX1, x15
    sw x1, X2, x15
    sw  x1, Y1, x15
    sw  x1, Y2, x15
    
    la x3,  M00
    lw x4, TWOFIVESIX
    add x4, x4, x4
    add x4, x3, x4
    andi x6, x6, 0


Continue1_3:

    lw x1, X2
    lw x2, Y2
    jal x7,  CalAddress
    add x7, x5, x3
    lw x6, 0(x7)
    jal x7,  CalNEXT1
    sw x1, X2, x15
    sw x2, Y2, x15
    
    lw x1, XX1
    lw x2, Y1
    jal x7,  CalAddress
    add x5, x5, x4
    lw x7, 0(x5)
    add x6, x6, x7
    sw x6, 0(x5)
    
    jal x7,  CalNEXT3
    addi x7, x1, 0
    bgt x0, x7, Done4
    sw x1, XX1, x15
    sw x2, Y1, x15
    
    beq x0, x0, Continue1_3
Done4:

HALT:
    beq x0, x0, HALT

CalNEXT1:

    addi x5, x1, -15
    beq x0, x5, YTEST
    addi x1, x1, 1
    beq x0, x0, SKip

YTEST:
    addi x5, x2, -15
    beq x0, x5, DoneFor
    addi x2, x2, 1
    andi x1, x1, 0
    beq x0, x0, SKip

DoneFor:
    andi x1, x1, 0
    addi x1, x1, -1

SKip:
    jalr x0, x7, 0

CalNEXT2:

    addi x5, x2, -15
    beq x0, x5, XTEST
    addi x2, x2, 1
    beq x0, x0, SKip1

XTEST:
    addi x5, x1, -15
    beq x0, x5, Done1
    addi x1, x1, 1
    andi x2, x2, 0
    beq x0, x0, SKip1

Done1:
    andi x1, x1, 0
    addi x1, x1, -1

SKip1:
    jalr x0, x7, 0

CalNEXT3:

    sw x3, TEMP3, x15
    addi x3, x1, -15
    beq x0, x3, DRow
    addi x3, x2, 0
    beq x0, x3, DRow1
    lw x3, NEGONEFIVE
    addi x3, x1, -15
    beq x0, x3, DRow
    
    addi x1, x1, 1
    addi x2, x2, -1
    beq x0, x0, SKIP2

DRow1:
    addi x2, x1, 1
    andi x1, x1, 0
    beq x0, x0, SKIP2

DRow:
    addi x3, x2, -15
    beq x0, x3, Done2

    addi x1, x2, 1
    andi x2, x2, 0
    addi x2, x2, 15
    beq x0, x0, SKIP2

Done2:
    andi x1, x1, 0
    addi x1, x1, -1

SKIP2:
    lw x3, TEMP3
    jalr x0, x7, 0

CalAddress:
    slli x5, x2, 5
    add x5, x1, x5
    slli x5, x5, 2
    jalr x0, x7, 0


.section .rodata
.balign 256
XX1:             .word    0x00000000
Y1:             .word    0x00000000
X2:             .word    0x00000000
Y2:             .word    0x00000000
TEMP1:          .word    0x00000000
TEMP2:          .word    0x00000000
TEMP3:          .word    0x00000000
TEMP4:          .word    0x00000000
TWOFIVESIX:     .word       256
UpperMemStart:  .word    0xF000F000
Counter1:       .word    0x00000FFF
Counter2:       .word    0x00004A3F
ONEFOURTHREE:   .word        63
NEGONEFIVE:     .word       -15
Mask:           .word    0x000000FF

M00:    .word           0x00000000