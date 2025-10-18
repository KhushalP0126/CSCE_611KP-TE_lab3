    .text
    .globl _start
_start:
    # Read 8-bit binary input from CSR io0
    csrrw   t0, 0xf00, x0     # binary input (t0)
    
    # Clear BCD digits
    li s0, 0
    li s1, 0
    li s2, 0
    li s3, 0
    li s4, 0
    li s5, 0
    li s6, 0
    li s7, 0


    ###########################################
    # ==== ITERATION 1 ====
    ###########################################
    slti    t2, s7, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s7, s7, t4

    slti    t2, s6, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s6, s6, t4

    slti    t2, s5, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s5, s5, t4

    slti    t2, s4, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s4, s4, t4

    slti    t2, s3, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s3, s3, t4

    slti    t2, s2, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s2, s2, t4

    slti    t2, s1, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s1, s1, t4

    slti    t2, s0, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s0, s0, t4

    # Shift binary input and BCD digits
    srli    t2, t0, 7         # MSB for 8-bit input
    slli    t0, t0, 1
    srli    t3, s0, 3
    slli    s0, s0, 1
    andi    s0, s0, 0xE
    or      s0, s0, t2
    mv      t3, t3

    srli    t2, s1, 3
    slli    s1, s1, 1
    andi    s1, s1, 0xE
    or      s1, s1, t3
    mv      t3, t2

    srli    t2, s2, 3
    slli    s2, s2, 1
    andi    s2, s2, 0xE
    or      s2, s2, t3
    mv      t3, t2

    srli    t2, s3, 3
    slli    s3, s3, 1
    andi    s3, s3, 0xE
    or      s3, s3, t3
    mv      t3, t2

    srli    t2, s4, 3
    slli    s4, s4, 1
    andi    s4, s4, 0xE
    or      s4, s4, t3
    mv      t3, t2

    srli    t2, s5, 3
    slli    s5, s5, 1
    andi    s5, s5, 0xE
    or      s5, s5, t3
    mv      t3, t2

    srli    t2, s6, 3
    slli    s6, s6, 1
    andi    s6, s6, 0xE
    or      s6, s6, t3
    mv      t3, t2

    slli    s7, s7, 1
    andi    s7, s7, 0xE
    or      s7, s7, t3

     ###########################################
    # ==== ITERATION 2 ====
    ###########################################
    slti    t2, s7, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s7, s7, t4

    slti    t2, s6, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s6, s6, t4

    slti    t2, s5, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s5, s5, t4

    slti    t2, s4, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s4, s4, t4

    slti    t2, s3, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s3, s3, t4

    slti    t2, s2, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s2, s2, t4

    slti    t2, s1, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s1, s1, t4

    slti    t2, s0, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s0, s0, t4

    # Shift binary input and BCD digits
    srli    t2, t0, 7         # MSB for 8-bit input
    slli    t0, t0, 1
    srli    t3, s0, 3
    slli    s0, s0, 1
    andi    s0, s0, 0xE
    or      s0, s0, t2
    mv      t3, t3

    srli    t2, s1, 3
    slli    s1, s1, 1
    andi    s1, s1, 0xE
    or      s1, s1, t3
    mv      t3, t2

    srli    t2, s2, 3
    slli    s2, s2, 1
    andi    s2, s2, 0xE
    or      s2, s2, t3
    mv      t3, t2

    srli    t2, s3, 3
    slli    s3, s3, 1
    andi    s3, s3, 0xE
    or      s3, s3, t3
    mv      t3, t2

    srli    t2, s4, 3
    slli    s4, s4, 1
    andi    s4, s4, 0xE
    or      s4, s4, t3
    mv      t3, t2

    srli    t2, s5, 3
    slli    s5, s5, 1
    andi    s5, s5, 0xE
    or      s5, s5, t3
    mv      t3, t2

    srli    t2, s6, 3
    slli    s6, s6, 1
    andi    s6, s6, 0xE
    or      s6, s6, t3
    mv      t3, t2

    slli    s7, s7, 1
    andi    s7, s7, 0xE
    or      s7, s7, t3

    ###########################################
    # ==== ITERATION 3 ====
    ###########################################
    slti    t2, s7, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s7, s7, t4

    slti    t2, s6, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s6, s6, t4

    slti    t2, s5, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s5, s5, t4

    slti    t2, s4, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s4, s4, t4

    slti    t2, s3, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s3, s3, t4

    slti    t2, s2, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s2, s2, t4

    slti    t2, s1, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s1, s1, t4

    slti    t2, s0, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s0, s0, t4

    # Shift binary input and BCD digits
    srli    t2, t0, 7         # MSB for 8-bit input
    slli    t0, t0, 1
    srli    t3, s0, 3
    slli    s0, s0, 1
    andi    s0, s0, 0xE
    or      s0, s0, t2
    mv      t3, t3

    srli    t2, s1, 3
    slli    s1, s1, 1
    andi    s1, s1, 0xE
    or      s1, s1, t3
    mv      t3, t2

    srli    t2, s2, 3
    slli    s2, s2, 1
    andi    s2, s2, 0xE
    or      s2, s2, t3
    mv      t3, t2

    srli    t2, s3, 3
    slli    s3, s3, 1
    andi    s3, s3, 0xE
    or      s3, s3, t3
    mv      t3, t2

    srli    t2, s4, 3
    slli    s4, s4, 1
    andi    s4, s4, 0xE
    or      s4, s4, t3
    mv      t3, t2

    srli    t2, s5, 3
    slli    s5, s5, 1
    andi    s5, s5, 0xE
    or      s5, s5, t3
    mv      t3, t2

    srli    t2, s6, 3
    slli    s6, s6, 1
    andi    s6, s6, 0xE
    or      s6, s6, t3
    mv      t3, t2

    slli    s7, s7, 1
    andi    s7, s7, 0xE
    or      s7, s7, t3

    ###########################################
    # ==== ITERATION 4 ====
    ###########################################
    slti    t2, s7, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s7, s7, t4

    slti    t2, s6, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s6, s6, t4

    slti    t2, s5, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s5, s5, t4

    slti    t2, s4, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s4, s4, t4

    slti    t2, s3, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s3, s3, t4

    slti    t2, s2, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s2, s2, t4

    slti    t2, s1, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s1, s1, t4

    slti    t2, s0, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s0, s0, t4

    # Shift binary input and BCD digits
    srli    t2, t0, 7         # MSB for 8-bit input
    slli    t0, t0, 1
    srli    t3, s0, 3
    slli    s0, s0, 1
    andi    s0, s0, 0xE
    or      s0, s0, t2
    mv      t3, t3

    srli    t2, s1, 3
    slli    s1, s1, 1
    andi    s1, s1, 0xE
    or      s1, s1, t3
    mv      t3, t2

    srli    t2, s2, 3
    slli    s2, s2, 1
    andi    s2, s2, 0xE
    or      s2, s2, t3
    mv      t3, t2

    srli    t2, s3, 3
    slli    s3, s3, 1
    andi    s3, s3, 0xE
    or      s3, s3, t3
    mv      t3, t2

    srli    t2, s4, 3
    slli    s4, s4, 1
    andi    s4, s4, 0xE
    or      s4, s4, t3
    mv      t3, t2

    srli    t2, s5, 3
    slli    s5, s5, 1
    andi    s5, s5, 0xE
    or      s5, s5, t3
    mv      t3, t2

    srli    t2, s6, 3
    slli    s6, s6, 1
    andi    s6, s6, 0xE
    or      s6, s6, t3
    mv      t3, t2

    slli    s7, s7, 1
    andi    s7, s7, 0xE
    or      s7, s7, t3

    ###########################################
    # ==== ITERATION 5 ====
    ###########################################
    slti    t2, s7, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s7, s7, t4

    slti    t2, s6, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s6, s6, t4

    slti    t2, s5, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s5, s5, t4

    slti    t2, s4, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s4, s4, t4

    slti    t2, s3, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s3, s3, t4

    slti    t2, s2, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s2, s2, t4

    slti    t2, s1, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s1, s1, t4

    slti    t2, s0, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s0, s0, t4

    # Shift binary input and BCD digits
    srli    t2, t0, 7         # MSB for 8-bit input
    slli    t0, t0, 1
    srli    t3, s0, 3
    slli    s0, s0, 1
    andi    s0, s0, 0xE
    or      s0, s0, t2
    mv      t3, t3

    srli    t2, s1, 3
    slli    s1, s1, 1
    andi    s1, s1, 0xE
    or      s1, s1, t3
    mv      t3, t2

    srli    t2, s2, 3
    slli    s2, s2, 1
    andi    s2, s2, 0xE
    or      s2, s2, t3
    mv      t3, t2

    srli    t2, s3, 3
    slli    s3, s3, 1
    andi    s3, s3, 0xE
    or      s3, s3, t3
    mv      t3, t2

    srli    t2, s4, 3
    slli    s4, s4, 1
    andi    s4, s4, 0xE
    or      s4, s4, t3
    mv      t3, t2

    srli    t2, s5, 3
    slli    s5, s5, 1
    andi    s5, s5, 0xE
    or      s5, s5, t3
    mv      t3, t2

    srli    t2, s6, 3
    slli    s6, s6, 1
    andi    s6, s6, 0xE
    or      s6, s6, t3
    mv      t3, t2

    slli    s7, s7, 1
    andi    s7, s7, 0xE
    or      s7, s7, t3

    ###########################################
    # ==== ITERATION 6 ====
    ###########################################
    slti    t2, s7, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s7, s7, t4

    slti    t2, s6, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s6, s6, t4

    slti    t2, s5, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s5, s5, t4

    slti    t2, s4, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s4, s4, t4

    slti    t2, s3, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s3, s3, t4

    slti    t2, s2, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s2, s2, t4

    slti    t2, s1, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s1, s1, t4

    slti    t2, s0, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s0, s0, t4

    # Shift binary input and BCD digits
    srli    t2, t0, 7         # MSB for 8-bit input
    slli    t0, t0, 1
    srli    t3, s0, 3
    slli    s0, s0, 1
    andi    s0, s0, 0xE
    or      s0, s0, t2
    mv      t3, t3

    srli    t2, s1, 3
    slli    s1, s1, 1
    andi    s1, s1, 0xE
    or      s1, s1, t3
    mv      t3, t2

    srli    t2, s2, 3
    slli    s2, s2, 1
    andi    s2, s2, 0xE
    or      s2, s2, t3
    mv      t3, t2

    srli    t2, s3, 3
    slli    s3, s3, 1
    andi    s3, s3, 0xE
    or      s3, s3, t3
    mv      t3, t2

    srli    t2, s4, 3
    slli    s4, s4, 1
    andi    s4, s4, 0xE
    or      s4, s4, t3
    mv      t3, t2

    srli    t2, s5, 3
    slli    s5, s5, 1
    andi    s5, s5, 0xE
    or      s5, s5, t3
    mv      t3, t2

    srli    t2, s6, 3
    slli    s6, s6, 1
    andi    s6, s6, 0xE
    or      s6, s6, t3
    mv      t3, t2

    slli    s7, s7, 1
    andi    s7, s7, 0xE
    or      s7, s7, t3

    ###########################################
    # ==== ITERATION 7 ====
    ###########################################
    slti    t2, s7, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s7, s7, t4

    slti    t2, s6, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s6, s6, t4

    slti    t2, s5, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s5, s5, t4

    slti    t2, s4, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s4, s4, t4

    slti    t2, s3, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s3, s3, t4

    slti    t2, s2, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s2, s2, t4

    slti    t2, s1, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s1, s1, t4

    slti    t2, s0, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s0, s0, t4

    # Shift binary input and BCD digits
    srli    t2, t0, 7         # MSB for 8-bit input
    slli    t0, t0, 1
    srli    t3, s0, 3
    slli    s0, s0, 1
    andi    s0, s0, 0xE
    or      s0, s0, t2
    mv      t3, t3

    srli    t2, s1, 3
    slli    s1, s1, 1
    andi    s1, s1, 0xE
    or      s1, s1, t3
    mv      t3, t2

    srli    t2, s2, 3
    slli    s2, s2, 1
    andi    s2, s2, 0xE
    or      s2, s2, t3
    mv      t3, t2

    srli    t2, s3, 3
    slli    s3, s3, 1
    andi    s3, s3, 0xE
    or      s3, s3, t3
    mv      t3, t2

    srli    t2, s4, 3
    slli    s4, s4, 1
    andi    s4, s4, 0xE
    or      s4, s4, t3
    mv      t3, t2

    srli    t2, s5, 3
    slli    s5, s5, 1
    andi    s5, s5, 0xE
    or      s5, s5, t3
    mv      t3, t2

    srli    t2, s6, 3
    slli    s6, s6, 1
    andi    s6, s6, 0xE
    or      s6, s6, t3
    mv      t3, t2

    slli    s7, s7, 1
    andi    s7, s7, 0xE
    or      s7, s7, t3

    ###########################################
    # ==== ITERATION 8 ====
    ###########################################
    slti    t2, s7, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s7, s7, t4

    slti    t2, s6, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s6, s6, t4

    slti    t2, s5, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s5, s5, t4

    slti    t2, s4, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s4, s4, t4

    slti    t2, s3, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s3, s3, t4

    slti    t2, s2, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s2, s2, t4

    slti    t2, s1, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s1, s1, t4

    slti    t2, s0, 5
    xori    t2, t2, 1
    slli    t4, t2, 1
    add     t4, t4, t2
    add     s0, s0, t4

    # Shift binary input and BCD digits
    srli    t2, t0, 7         # MSB for 8-bit input
    slli    t0, t0, 1
    srli    t3, s0, 3
    slli    s0, s0, 1
    andi    s0, s0, 0xE
    or      s0, s0, t2
    mv      t3, t3

    srli    t2, s1, 3
    slli    s1, s1, 1
    andi    s1, s1, 0xE
    or      s1, s1, t3
    mv      t3, t2

    srli    t2, s2, 3
    slli    s2, s2, 1
    andi    s2, s2, 0xE
    or      s2, s2, t3
    mv      t3, t2

    srli    t2, s3, 3
    slli    s3, s3, 1
    andi    s3, s3, 0xE
    or      s3, s3, t3
    mv      t3, t2

    srli    t2, s4, 3
    slli    s4, s4, 1
    andi    s4, s4, 0xE
    or      s4, s4, t3
    mv      t3, t2

    srli    t2, s5, 3
    slli    s5, s5, 1
    andi    s5, s5, 0xE
    or      s5, s5, t3
    mv      t3, t2

    srli    t2, s6, 3
    slli    s6, s6, 1
    andi    s6, s6, 0xE
    or      s6, s6, t3
    mv      t3, t2

    slli    s7, s7, 1
    andi    s7, s7, 0xE
    or      s7, s7, t3


    # ==== Final pack to output (after 8th iteration) ====
    mv      t3, s7
    slli    t3, t3, 4
    or      t3, t3, s6
    slli    t3, t3, 4
    or      t3, t3, s5
    slli    t3, t3, 4
    or      t3, t3, s4
    slli    t3, t3, 4
    or      t3, t3, s3
    slli    t3, t3, 4
    or      t3, t3, s2
    slli    t3, t3, 4
    or      t3, t3, s1
    slli    t3, t3, 4
    or      t3, t3, s0

    # Write result to CSR io2 for HEX display
    csrrw   x0, 0xf02, t3

halt:
    j halt

