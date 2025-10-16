    # bin2dec.asm - binary -> decimal (packed nibbles) for the CSCE611 lab
    # Reads input from CSR io0 (0xF00), writes packed decimal to CSR io2 (0xF02).
    # Uses double-dabble (shift-add-3) to convert 32-bit value into 8 decimal digits
    # packed into 8 nibbles (HEX7..HEX0). No DIV instruction required.
    #
    # NOTES:
    # - If RARS isn't available to supply io0 at run-time, uncomment the LI_INPUT
    #   block to use a hard-coded test value (useful for simulation).
    # - If you want more than 8 decimal digits, you'd need to increase the BCD width.
    # - After writing the output CSR, the program loops forever.

    .section .text
    .globl _start
_start:
    # ---------------------------
    # Read input from CSR io0
    # ---------------------------
    # Try runtime read:
    csrrw   x10, 0xf00, x0     # a0 <- io0 (CSR 0xF00), don't write anything

    # If you don't have RARS or can't read io0 during early testing,
    # comment the csrrw above and uncomment one of these hard-coded tests:
    # li  x10, 0x000001EF      # test: 0x1EF = 495 decimal
    # li  x10, 0x0000002A      # test: 42 decimal
    # li  x10, 12345678        # test: 12,345,678 (fits in 8 digits)

    # a0 = input value to convert
    mv      t0, x10           # t0 holds the input value to shift (we'll shift bits out)

    # ---------------------------
    # Initialize BCD digits d7..d0 = 0
    # We'll hold them in registers s0..s7 (x8..x15)
    # s0 -> least significant decimal digit (units)
    # s7 -> most significant decimal digit (10^7)
    # ---------------------------
    li      s0, 0
    li      s1, 0
    li      s2, 0
    li      s3, 0
    li      s4, 0
    li      s5, 0
    li      s6, 0
    li      s7, 0

    li      t1, 32            # bit loop counter (i = 32 down to 1)

bitloop:
    # For each BCD digit: if digit >= 5 then add 3
    # We'll use sltiu to test (digit < 5) ; if result==0 then digit >=5
    li      t2, 5
    sltiu   t3, s0, 5
    bne     t3, x0, skip_add0
    addi    s0, s0, 3
skip_add0:
    sltiu   t3, s1, 5
    bne     t3, x0, skip_add1
    addi    s1, s1, 3
skip_add1:
    sltiu   t3, s2, 5
    bne     t3, x0, skip_add2
    addi    s2, s2, 3
skip_add2:
    sltiu   t3, s3, 5
    bne     t3, x0, skip_add3
    addi    s3, s3, 3
skip_add3:
    sltiu   t3, s4, 5
    bne     t3, x0, skip_add4
    addi    s4, s4, 3
skip_add4:
    sltiu   t3, s5, 5
    bne     t3, x0, skip_add5
    addi    s5, s5, 3
skip_add5:
    sltiu   t3, s6, 5
    bne     t3, x0, skip_add6
    addi    s6, s6, 3
skip_add6:
    sltiu   t3, s7, 5
    bne     t3, x0, skip_add7
    addi    s7, s7, 3
skip_add7:

    # Now shift left the whole BCD array by 1 bit, inserting the next MSB of t0
    # We shift from most significant digit down to least, carrying bits between them.

    # Extract the top bit of t0 (bit 31 of current t0)
    slli    t4, t0, 0         # t4 = t0 (copy)
    srli    t4, t4, 31        # t4 = (t0 >> 31) & 1  --- this is the bit to inject
    # shift t0 left by 1 for next iteration
    slli    t0, t0, 1

    # We'll perform digit shifts with carries.
    # For each digit: new_digit = ((digit << 1) & 0xF) | carry_in
    # carry_out = (digit >> 3) & 1  (since digit is 4-bit, msb is bit3 before shift)

    # Digit s7 (MSD)
    slli    t5, s7, 1         # t5 = s7 << 1
    srli    t6, s7, 3         # t6 = old s7 bit3 -> carry_out
    andi    t5, t5, 0xF       # mask to 4 bits (not strictly necessary but safe)
    or      s7, t5, t4        # s7 = shifted | carry_in
    mv      t4, t6            # new carry_in = carry_out for next digit

    # s6
    slli    t5, s6, 1
    srli    t6, s6, 3
    andi    t5, t5, 0xF
    or      s6, t5, t4
    mv      t4, t6

    # s5
    slli    t5, s5, 1
    srli    t6, s5, 3
    andi    t5, t5, 0xF
    or      s5, t5, t4
    mv      t4, t6

    # s4
    slli    t5, s4, 1
    srli    t6, s4, 3
    andi    t5, t5, 0xF
    or      s4, t5, t4
    mv      t4, t6

    # s3
    slli    t5, s3, 1
    srli    t6, s3, 3
    andi    t5, t5, 0xF
    or      s3, t5, t4
    mv      t4, t6

    # s2
    slli    t5, s2, 1
    srli    t6, s2, 3
    andi    t5, t5, 0xF
    or      s2, t5, t4
    mv      t4, t6

    # s1
    slli    t5, s1, 1
    srli    t6, s1, 3
    andi    t5, t5, 0xF
    or      s1, t5, t4
    mv      t4, t6

    # s0 (LSD)
    slli    t5, s0, 1
    srli    t6, s0, 3
    andi    t5, t5, 0xF
    or      s0, t5, t4
    # t4 (carry out of s0) is discarded

    # decrement bit counter
    addi    t1, t1, -1
    bnez    t1, bitloop

    # ---------------------------
    # Pack BCD digits into 32-bit word:
    # result = (s7<<28) | (s6<<24) | ... | (s0<<0)
    # ---------------------------
    slli    t7, s7, 28
    slli    t6, s6, 24
    or      t7, t7, t6
    slli    t6, s5, 20
    or      t7, t7, t6
    slli    t6, s4, 16
    or      t7, t7, t6
    slli    t6, s3, 12
    or      t7, t7, t6
    slli    t6, s2, 8
    or      t7, t7, t6
    slli    t6, s1, 4
    or      t7, t7, t6
    or      t7, t7, s0        # t7 now has packed 8-digit BCD in nibbles

    # ---------------------------
    # Write result to CSR io2 (0xF02)
    # csrrw rd, csr, rs1  ; rd <- old CSR, CSR <- rs1
    # We don't care about the readback, so use x0 as rd.
    # ---------------------------
    mv      x12, t7
    csrrw   x0, 0xf02, x12    # write packed decimal to io2

done_loop:
    # stay here forever (so output remains visible)
    j done_loop

