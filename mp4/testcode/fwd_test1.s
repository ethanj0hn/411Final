fwd_test.s:
.align 4
.section .text
.globl _start
<<<<<<< Updated upstream
# if test works, see 4 in x1
_start:
    addi x1,x0,1 # x1 <- 1
    # add x1,x1,x1 # x1 <- 2
    add x1,x1,x1 # x1 <- 4
=======
# if test works, see 8 in x1
_start:
    # checks alu forwarding
    addi x1,x0,1
    add x1,x1,x1 # x1 <-2
>>>>>>> Stashed changes
    nop
    add x1,x1,x1 # x1 <- 4
    add x1,x1,x1 # x1<- 8
    nop
    nop
    # checks cmp forwarding
    slti x2,x0,1 # x2 <- 1 (x0<1)
    add x2,x2,x2 # x2 <- 2
    add x2,x2,x2 # x2 <- 4
    nop
    la x3,bad # x3 <- bad
    # checks load logic and forwarding
    nop
    lbu x4,2(x3) # x4 <- 0x000000ad 
    add x4,x4,1 # x4 <- 0x000000ae
    add x4,x4,1 # x4 <- 0x000000af
    nop
    nop
    nop
    nop
    sb x4,1(x3) # M[bad] should see 0xdeadafef
halt:
    beq x0,x0,halt
    nop
    nop
    nop
    nop

bad:        .word 0xdeadbeef
good:       .word 0x600d600d
