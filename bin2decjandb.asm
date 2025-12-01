.text
    .globl _start
# Convert binary input from io0 into packed BCD for 8 HEX displays.
# Loop-based version that exercises branch/jump instructions.
_start:
    csrrw   t0, 0xf00, x0          # t0 = binary input from switches (io0)
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
