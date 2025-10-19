    .text
    .globl _start

# Convert binary input from io0 into packed BCD for 8 HEX displays.
# Uses fixed-point multiply by 0.1 combined with digit = value - quotient*10.
# NOPs are inserted to avoid pipeline hazards in the simple 3-stage CPU.
_start:
    csrrw   t0, 0xf00, x0          # t0 = binary input from switches (io0)

    lui     t1, 0x1999a            # high bits of 0.1 (Q32.32)
    addi    t1, t1, -0x666         # adjust low bits -> 0x1999999a

    addi    t2, x0, 10             # constant 10
    addi    s0, x0, 0              # clear packed BCD accumulator

    # ---- digit 0 (ones place) ----
    mulhu   t4, t0, t1             # quotient = value / 10
    addi    x0,  x0, 0             # bubble for pipeline
    mul     t5, t4, t2             # quotient * 10
    addi    x0,  x0, 0
    sub     t5, t0, t5             # digit = value - quotient*10
    addi    x0,  x0, 0
    andi    t5, t5, 0xF
    addi    x0,  x0, 0
    slli    t5, t5, 0
    addi    x0,  x0, 0
    or      s0, s0, t5
    addi    t0, t4, 0
    addi    x0,  x0, 0

    # ---- digit 1 (tens place) ----
    mulhu   t4, t0, t1
    addi    x0,  x0, 0
    mul     t5, t4, t2
    addi    x0,  x0, 0
    sub     t5, t0, t5
    addi    x0,  x0, 0
    andi    t5, t5, 0xF
    addi    x0,  x0, 0
    slli    t5, t5, 4
    addi    x0,  x0, 0
    or      s0, s0, t5
    addi    t0, t4, 0
    addi    x0,  x0, 0

    # ---- digit 2 (hundreds place) ----
    mulhu   t4, t0, t1
    addi    x0,  x0, 0
    mul     t5, t4, t2
    addi    x0,  x0, 0
    sub     t5, t0, t5
    addi    x0,  x0, 0
    andi    t5, t5, 0xF
    addi    x0,  x0, 0
    slli    t5, t5, 8
    addi    x0,  x0, 0
    or      s0, s0, t5
    addi    t0, t4, 0
    addi    x0,  x0, 0

    # ---- digit 3 (thousands place) ----
    mulhu   t4, t0, t1
    addi    x0,  x0, 0
    mul     t5, t4, t2
    addi    x0,  x0, 0
    sub     t5, t0, t5
    addi    x0,  x0, 0
    andi    t5, t5, 0xF
    addi    x0,  x0, 0
    slli    t5, t5, 12
    addi    x0,  x0, 0
    or      s0, s0, t5
    addi    t0, t4, 0
    addi    x0,  x0, 0

    # ---- digit 4 (ten-thousands place) ----
    mulhu   t4, t0, t1
    addi    x0,  x0, 0
    mul     t5, t4, t2
    addi    x0,  x0, 0
    sub     t5, t0, t5
    addi    x0,  x0, 0
    andi    t5, t5, 0xF
    addi    x0,  x0, 0
    slli    t5, t5, 16
    addi    x0,  x0, 0
    or      s0, s0, t5
    addi    t0, t4, 0
    addi    x0,  x0, 0

    # ---- digit 5 (hundred-thousands place) ----
    mulhu   t4, t0, t1
    addi    x0,  x0, 0
    mul     t5, t4, t2
    addi    x0,  x0, 0
    sub     t5, t0, t5
    addi    x0,  x0, 0
    andi    t5, t5, 0xF
    addi    x0,  x0, 0
    slli    t5, t5, 20
    addi    x0,  x0, 0
    or      s0, s0, t5
    addi    t0, t4, 0
    addi    x0,  x0, 0

    # ---- digit 6 (millions place) ----
    mulhu   t4, t0, t1
    addi    x0,  x0, 0
    mul     t5, t4, t2
    addi    x0,  x0, 0
    sub     t5, t0, t5
    addi    x0,  x0, 0
    andi    t5, t5, 0xF
    addi    x0,  x0, 0
    slli    t5, t5, 24
    addi    x0,  x0, 0
    or      s0, s0, t5
    addi    t0, t4, 0
    addi    x0,  x0, 0

    # ---- digit 7 (ten-millions place) ----
    mulhu   t4, t0, t1
    addi    x0,  x0, 0
    mul     t5, t4, t2
    addi    x0,  x0, 0
    sub     t5, t0, t5
    addi    x0,  x0, 0
    andi    t5, t5, 0xF
    addi    x0,  x0, 0
    slli    t5, t5, 28
    addi    x0,  x0, 0
    or      s0, s0, t5
    addi    t0, t4, 0
    addi    x0,  x0, 0

    csrrw   x0, 0xf02, s0          # write packed BCD to io2 (HEX displays)

    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
