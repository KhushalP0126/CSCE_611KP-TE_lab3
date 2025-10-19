    .text
    .globl _start

# Convert binary input from io0 into packed BCD for 8 HEX displays.
# Implements TA guidance: fixed-point multiply by 0.1 with eight unrolled stages
# (no branches) suitable for the simple three-stage pipeline.
_start:
    csrrw   t0, 0xf00, x0          # t0 = binary input from switches (io0)

    li      t1, 0x1999999a         # 0.1 in Q32.32 format
    li      t3, 10                 # constant 10
    li      s0, 0                  # BCD accumulator (HEX7..HEX0)

    # ---- digit 0 (ones place) ----
    mul     t5, t0, t1
    mulhu   t6, t0, t1
    mulhu   t7, t5, t3
    andi    t7, t7, 0xF
    or      s0, s0, t7
    addi    t0, t6, 0

    # ---- digit 1 (tens place) ----
    mul     t5, t0, t1
    mulhu   t6, t0, t1
    mulhu   t7, t5, t3
    andi    t7, t7, 0xF
    slli    t7, t7, 4
    or      s0, s0, t7
    addi    t0, t6, 0

    # ---- digit 2 (hundreds place) ----
    mul     t5, t0, t1
    mulhu   t6, t0, t1
    mulhu   t7, t5, t3
    andi    t7, t7, 0xF
    slli    t7, t7, 8
    or      s0, s0, t7
    addi    t0, t6, 0

    # ---- digit 3 (thousands place) ----
    mul     t5, t0, t1
    mulhu   t6, t0, t1
    mulhu   t7, t5, t3
    andi    t7, t7, 0xF
    slli    t7, t7, 12
    or      s0, s0, t7
    addi    t0, t6, 0

    # ---- digit 4 (ten-thousands place) ----
    mul     t5, t0, t1
    mulhu   t6, t0, t1
    mulhu   t7, t5, t3
    andi    t7, t7, 0xF
    slli    t7, t7, 16
    or      s0, s0, t7
    addi    t0, t6, 0

    # ---- digit 5 (hundred-thousands place) ----
    mul     t5, t0, t1
    mulhu   t6, t0, t1
    mulhu   t7, t5, t3
    andi    t7, t7, 0xF
    slli    t7, t7, 20
    or      s0, s0, t7
    addi    t0, t6, 0

    # ---- digit 6 (millions place) ----
    mul     t5, t0, t1
    mulhu   t6, t0, t1
    mulhu   t7, t5, t3
    andi    t7, t7, 0xF
    slli    t7, t7, 24
    or      s0, s0, t7
    addi    t0, t6, 0

    # ---- digit 7 (ten-millions place) ----
    mul     t5, t0, t1
    mulhu   t6, t0, t1
    mulhu   t7, t5, t3
    andi    t7, t7, 0xF
    slli    t7, t7, 28
    or      s0, s0, t7
    addi    t0, t6, 0

    csrrw   x0, 0xf02, s0          # write packed BCD to io2 (HEX displays)

    addi    x0, x0, 0              # execute harmless nops thereafter
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
