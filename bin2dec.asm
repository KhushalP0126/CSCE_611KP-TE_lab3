.text
    .globl _start
# Convert binary input from io0 into packed BCD for 8 HEX displays.
# Uses fixed-point multiply by 0.1 combined with digit = value - quotient*10.
# TWO NOPs are inserted after each instruction that writes a register
# to avoid pipeline hazards in the 3-stage CPU (F->EX->WB).
_start:
    csrrw   t0, 0xf00, x0          # t0 = binary input from switches (io0)
    addi    x0, x0, 0              # NOP - CSR result propagating
    addi    x0, x0, 0              # NOP - t0 write completes
    lui     t1, 0x1999a            # high bits of 0.1 (Q32.32)
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    addi    t1, t1, -0x666         # adjust low bits -> 0x1999999a
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    addi    t2, x0, 10             # constant 10
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    addi    s0, x0, 0              # clear packed BCD accumulator
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    
    # ---- digit 0 (ones place) ----
    mulhu   t4, t0, t1             # quotient = value / 10
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    mul     t5, t4, t2             # quotient * 10
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    sub     t5, t0, t5             # digit = value - quotient*10
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    andi    t5, t5, 0xF            # mask to 4 bits
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    slli    t5, t5, 28             # bits 28-31 (HEX0 - rightmost display)
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    or      s0, s0, t5
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    addi    t0, t4, 0              # move quotient to t0 for next digit
    addi    x0, x0, 0              # NOP
    addi    x0, x0, 0              # NOP
    
    # ---- digit 1 (tens place) ----
    mulhu   t4, t0, t1
    addi    x0, x0, 0
    addi    x0, x0, 0
    mul     t5, t4, t2
    addi    x0, x0, 0
    addi    x0, x0, 0
    sub     t5, t0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    andi    t5, t5, 0xF
    addi    x0, x0, 0
    addi    x0, x0, 0
    slli    t5, t5, 24             # bits 24-27 (HEX1)
    addi    x0, x0, 0
    addi    x0, x0, 0
    or      s0, s0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    t0, t4, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
    
    # ---- digit 2 (hundreds place) ----
    mulhu   t4, t0, t1
    addi    x0, x0, 0
    addi    x0, x0, 0
    mul     t5, t4, t2
    addi    x0, x0, 0
    addi    x0, x0, 0
    sub     t5, t0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    andi    t5, t5, 0xF
    addi    x0, x0, 0
    addi    x0, x0, 0
    slli    t5, t5, 20             # bits 20-23 (HEX2)
    addi    x0, x0, 0
    addi    x0, x0, 0
    or      s0, s0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    t0, t4, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
    
    # ---- digit 3 (thousands place) ----
    mulhu   t4, t0, t1
    addi    x0, x0, 0
    addi    x0, x0, 0
    mul     t5, t4, t2
    addi    x0, x0, 0
    addi    x0, x0, 0
    sub     t5, t0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    andi    t5, t5, 0xF
    addi    x0, x0, 0
    addi    x0, x0, 0
    slli    t5, t5, 16             # bits 16-19 (HEX3)
    addi    x0, x0, 0
    addi    x0, x0, 0
    or      s0, s0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    t0, t4, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
    
    # ---- digit 4 (ten-thousands place) ----
    mulhu   t4, t0, t1
    addi    x0, x0, 0
    addi    x0, x0, 0
    mul     t5, t4, t2
    addi    x0, x0, 0
    addi    x0, x0, 0
    sub     t5, t0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    andi    t5, t5, 0xF
    addi    x0, x0, 0
    addi    x0, x0, 0
    slli    t5, t5, 12             # bits 12-15 (HEX4)
    addi    x0, x0, 0
    addi    x0, x0, 0
    or      s0, s0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    t0, t4, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
    
    # ---- digit 5 (hundred-thousands place) ----
    mulhu   t4, t0, t1
    addi    x0, x0, 0
    addi    x0, x0, 0
    mul     t5, t4, t2
    addi    x0, x0, 0
    addi    x0, x0, 0
    sub     t5, t0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    andi    t5, t5, 0xF
    addi    x0, x0, 0
    addi    x0, x0, 0
    slli    t5, t5, 8              # bits 8-11 (HEX5)
    addi    x0, x0, 0
    addi    x0, x0, 0
    or      s0, s0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    t0, t4, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
    
    # ---- digit 6 (millions place) ----
    mulhu   t4, t0, t1
    addi    x0, x0, 0
    addi    x0, x0, 0
    mul     t5, t4, t2
    addi    x0, x0, 0
    addi    x0, x0, 0
    sub     t5, t0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    andi    t5, t5, 0xF
    addi    x0, x0, 0
    addi    x0, x0, 0
    slli    t5, t5, 4              # bits 4-7 (HEX6)
    addi    x0, x0, 0
    addi    x0, x0, 0
    or      s0, s0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    t0, t4, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
    
    # ---- digit 7 (ten-millions place) ----
    mulhu   t4, t0, t1
    addi    x0, x0, 0
    addi    x0, x0, 0
    mul     t5, t4, t2
    addi    x0, x0, 0
    addi    x0, x0, 0
    sub     t5, t0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    andi    t5, t5, 0xF
    addi    x0, x0, 0
    addi    x0, x0, 0
    slli    t5, t5, 0              # bits 0-3 (HEX7 - leftmost display)
    addi    x0, x0, 0
    addi    x0, x0, 0
    or      s0, s0, t5
    addi    x0, x0, 0
    addi    x0, x0, 0
    
    # Write packed BCD to io2 (HEX displays)
    csrrw   x0, 0xf02, s0
    addi    x0, x0, 0
    addi    x0, x0, 0
    
    # Infinite loop to keep result displayed
    addi    x0, x0, 0
    addi    x0, x0, 0
