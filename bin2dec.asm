    .text
    .globl _start

# Convert binary input from io0 into packed BCD for 8 HEX displays.
# Implements TA guidance: fixed-point multiply by 0.1 with eight unrolled stages
# using base RISC-V integer + M-extension ops only (no branches).
_start:
    csrrw   t0, 0xf00, x0          # t0 = binary input from switches (io0)

    lui     t1, 0x1999a            # t1 = upper bits of 0.1 (Q32.32)
    addi    t1, t1, -0x666         # adjust low bits, final constant = 0x1999999a

    addi    t2, x0, 10             # t2 = constant 10
    addi    s0, x0, 0              # s0 = packed BCD accumulator

    # ---- digit 0 (ones place) ----
    mul     t3, t0, t1
    mulhu   t4, t0, t1
    mulhu   t5, t3, t2
    andi    t5, t5, 0xF
    slli    t5, t5, 0
    or      s0, s0, t5
    addi    t0, t4, 0

    # ---- digit 1 (tens place) ----
    mul     t3, t0, t1
    mulhu   t4, t0, t1
    mulhu   t5, t3, t2
    andi    t5, t5, 0xF
    slli    t5, t5, 4
    or      s0, s0, t5
    addi    t0, t4, 0

    # ---- digit 2 (hundreds place) ----
    mul     t3, t0, t1
    mulhu   t4, t0, t1
    mulhu   t5, t3, t2
    andi    t5, t5, 0xF
    slli    t5, t5, 8
    or      s0, s0, t5
    addi    t0, t4, 0

    # ---- digit 3 (thousands place) ----
    mul     t3, t0, t1
    mulhu   t4, t0, t1
    mulhu   t5, t3, t2
    andi    t5, t5, 0xF
    slli    t5, t5, 12
    or      s0, s0, t5
    addi    t0, t4, 0

    # ---- digit 4 (ten-thousands place) ----
    mul     t3, t0, t1
    mulhu   t4, t0, t1
    mulhu   t5, t3, t2
    andi    t5, t5, 0xF
    slli    t5, t5, 16
    or      s0, s0, t5
    addi    t0, t4, 0

    # ---- digit 5 (hundred-thousands place) ----
    mul     t3, t0, t1
    mulhu   t4, t0, t1
    mulhu   t5, t3, t2
    andi    t5, t5, 0xF
    slli    t5, t5, 20
    or      s0, s0, t5
    addi    t0, t4, 0

    # ---- digit 6 (millions place) ----
    mul     t3, t0, t1
    mulhu   t4, t0, t1
    mulhu   t5, t3, t2
    andi    t5, t5, 0xF
    slli    t5, t5, 24
    or      s0, s0, t5
    addi    t0, t4, 0

    # ---- digit 7 (ten-millions place) ----
    mul     t3, t0, t1
    mulhu   t4, t0, t1
    mulhu   t5, t3, t2
    andi    t5, t5, 0xF
    slli    t5, t5, 28
    or      s0, s0, t5
    addi    t0, t4, 0

    csrrw   x0, 0xf02, s0          # write packed BCD to io2 (HEX displays)

    # Idle forever (acts as NOP pipeline filler)
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
    addi    x0, x0, 0
