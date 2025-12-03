.text
    .globl _start

# Square root with binary search, then convert to (8,5) decimal format
_start:
    # Read input from switches
    csrrw   a0, 0xf00, x0         # a0 = input value from switches (io0)
    
    # Convert input to Q18.14 fixed-point format
    slli    a0, a0, 14             # a0 = input << 14 (convert to Q18.14)
    
    #debug
    addi    s0, a0, 0
    csrrw   x0, 0xf02, s0
    j       halt
    
    # Initialize square root computation (binary search)
    addi    sp, x0, 0              # sp = current guess = 0
    addi    gp, x0, 256            # gp = step size = 256
    slli    gp, gp, 14             # gp = 256 << 14 (start with large step in Q18.14)
    
sqrt_loop:
    # Square the current guess: (sp * sp) >> 14
    mul     tp, sp, sp             # tp = low 32 bits of sp^2
    mulhu   t1, sp, sp             # t1 = high 32 bits of sp^2
    srli    tp, tp, 14             # shift low part right by 14
    slli    t1, t1, 18             # shift high part left by 18 (32-14=18)
    or      tp, tp, t1             # tp = (sp^2) >> 14 (Q18.14 result)
    
    # Check if we found exact match
    beq     tp, a0, sqrt_done
    
    # Adjust guess based on comparison
    bltu    tp, a0, sqrt_too_small
    
sqrt_too_large:
    sub     sp, sp, gp             # guess too large, decrease it
    j       sqrt_continue
    
sqrt_too_small:
    add     sp, sp, gp             # guess too small, increase it
    
sqrt_continue:
    srli    gp, gp, 1              # halve the step size
    bnez    gp, sqrt_loop          # continue if step > 0
    
sqrt_done:
    # sp now contains square root in Q18.14 format
    # Convert to decimal: multiply by 100000, then divide by 16384 (2^14)
    
    # Move result to x1 for multiplication
    add     x1, x0, sp             # x1 = sp (sqrt result in Q18.14)
    
    # Load constant 100000
    li      a3, 100000             # Load the constant 100000
    
    # Multiply x1 * 100000
    mul     x2, x1, a3             # x2 = low 32 bits of x1 * 100000
    mulhu   x1, x1, a3             # x1 = high 32 bits of x1 * 100000
    
    # Now shift to divide by 16384 (2^14)
    slli    x1, x1, 18             # shift high part left (32-14=18)
    srli    x2, x2, 14             # shift low part right by 14
    
    # Combine the results
    or      x1, x1, x2             # x1 now has the final decimal result
    
    # Move to t0 for BCD conversion
    add     t0, x0, x1             # t0 = decimal value to convert
    
    # Now convert t0 to packed BCD using loop
    # t0 contains the decimal value to display
    
    # Setup for BCD conversion
    lui     t1, 0x1999a            # high bits of 0.1 (Q32.32)
    addi    t1, t1, -0x666         # adjust low bits -> 0x1999999a
    addi    t2, x0, 10             # constant 10 for division
    addi    s0, x0, 0              # clear packed BCD accumulator
    addi    t6, x0, 8              # loop counter (8 digits)
    addi    a2, x0, 28             # bit shift position (start at 28 for rightmost)
    
bcd_loop:
    # Extract one digit: digit = value % 10, value = value / 10
    mulhu   t4, t0, t1             # t4 = quotient (value / 10)
    mul     t5, t4, t2             # t5 = quotient * 10
    sub     t5, t0, t5             # t5 = digit (value - quotient*10)
    andi    t5, t5, 0xF            # mask to 4 bits
    sll     t5, t5, a2             # shift digit to correct position
    or      s0, s0, t5             # OR into packed BCD result
    
    # Setup for next iteration
    addi    t0, t4, 0              # move quotient to t0
    addi    a2, a2, -4             # decrease shift by 4 (next digit position)
    addi    t6, t6, -1             # decrement counter
    bnez    t6, bcd_loop           # loop if more digits remain
    
    # Pipeline bubbles to ensure completion
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    
    # Write packed BCD to io2 (HEX displays)
    csrrw   x0, 0xf02, s0
    
    # Infinite loop to halt
halt:
    j       halt
