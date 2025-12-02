.text
    .globl _start
# Square root with binary search, then convert to packed BCD for HEX displays.
# Input: binary value from io0 (switches)
# Output: square root in (8,5) fixed-point format displayed as 8-digit decimal
_start:
    # Read input from switches
    csrrw   a0, 0xf00, x0          # a0 = input value from switches (io0)
    
    # Initialize square root computation (binary search)
    addi    sp, x0, 0              # sp = current guess = 0
    addi    gp, x0, 256            # gp = step size = 256
    slli    gp, gp, 14             # gp = 256 << 14 (step in fixed-point Q18.14)
    
sqrt_loop:
    # Square the current guess: (sp * sp) >> 14
    mul     tp, sp, sp             # tp = low 32 bits of sp^2
    mulhu   t1, sp, sp             # t1 = high 32 bits of sp^2
    srli    tp, tp, 14             # shift low part right by 14
    slli    t1, t1, 18             # shift high part left by 18
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
    # sp now contains the square root in Q18.14 fixed-point format
    # Convert to (8,5) format by shifting: Q18.14 -> decimal with 5 fractional digits
    # We need to convert Q18.14 to integer representing decimal * 10^5
    
    # Multiply by 100000 (10^5) to convert fractional part to integer
    # sp is in Q18.14, so sp represents value * 2^14
    # To get value * 10^5, compute: (sp * 100000) / 16384
    
    lui     t1, 0x18               # load upper bits of 100000 (0x000186a0)
    addi    t1, t1, 0x6a0          # t1 = 0x000186a0 = 100000
    mul     t0, sp, t1             # t0 = sp * 100000 (low bits)
    mulhu   t2, sp, t1             # t2 = sp * 100000 (high bits)
    
    # Divide by 16384 (2^14) to adjust from Q18.14 to integer
    srli    t0, t0, 14             # shift low part right by 14
    slli    t2, t2, 18             # shift high part left by 18
    or      t0, t2, t0             # t0 = (sp * 100000) / 16384
    
    # Now convert t0 (decimal result) to packed BCD
    lui     t1, 0x1999a            # high bits of 0.1 (Q32.32)
    addi    t1, t1, -0x666         # adjust low bits -> 0x1999999a
    addi    t2, x0, 10             # constant 10
    addi    s0, x0, 0              # clear packed BCD accumulator
    addi    t3, x0, 28             # current shift amount (HEX0 starts at bits 28-31)
    addi    t6, x0, 8              # digits remaining

loop_digits:
    mulhu   t4, t0, t1             # quotient = value / 10
    mul     t5, t4, t2             # quotient * 10
    sub     t5, t0, t5             # digit = value - quotient*10
    andi    t5, t5, 0xF            # mask to 4 bits
    sll     t5, t5, t3             # place digit into packed BCD (HEX slot)
    or      s0, s0, t5
    addi    t0, t4, 0              # move quotient to t0 for next digit
    addi    t3, t3, -4             # next HEX position (shift decreases by 4)
    addi    t6, t6, -1
    bnez    t6, loop_digits
    
    # Write packed BCD to io2 (HEX displays)
    csrrw   x0, 0xf02, s0
    
    # Infinite loop to halt
halt:
    j       halt
