factorial.s:
.align 4
.section .text
.globl _start

# x1 stores result
# x2 what is to be added to x1 during the loop
# x3 tracks counter value
# x4 counter variable that is decremented in the loop
_start:
    # Note that the comments in this file should not be taken as1
    lw x2,factorial_operand # load operand
    blt x2,x0,halt # if less than 0, go to halt
    beq x2,x0,zero # if 0, load one to x1, go to halt

    andi x1,x1,0 # clear x1 for holding result
    addi x3,x2,-1 # give x3 init loop counter
    addi x4,x3,0 # give x4 counter that changes in loop
    


loop:
    add x1,x2,x1 # while temp loop counter (x4) > 0, add operand in x2 to x1 (result)
    addi x4,x4,-1
    bgt x4,x0,loop
    addi x3,x3,-1 # decrement loop var, if == 0 goto halt
    beq x3,x0,halt
    addi x2,x1,0 # load new add op to x2, clear x1
    andi x1,x1,0
    addi x4,x3,0 # load new counter
    j loop # jump to loop
    
     





halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below. 

zero:
    andi x1,x1,0
    addi x1,x1,1 # load 1 for 0 factorial
    j halt




factorial_operand:        .word 0x00000008 # factorial operand. (factorial_operand)! will be stored in x1 after program finishes
