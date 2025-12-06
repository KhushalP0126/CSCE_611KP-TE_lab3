// simtop.sv - Testbench matching all ports of the top.sv file
module simtop;
  // --- clocks (as in top.sv) ---
  logic CLOCK_50;
  logic CLOCK2_50;
  logic CLOCK3_50;
  // --- LEDs widths matching top.sv ---
  logic [8:0]  LEDG;
  logic [17:0] LEDR;
  // --- keys and switches matching top.sv ---
  logic [3:0]  KEY;
  logic [17:0] SW;
  // --- 7-seg displays matching top.sv --
  logic [6:0] HEX0;
  logic [6:0] HEX1;
  logic [6:0] HEX2;
  logic [6:0] HEX3;
  logic [6:0] HEX4;
  logic [6:0] HEX5;
  logic [6:0] HEX6;
  logic [6:0] HEX7;
  // ---------------- Test parameters ----------------
  
  parameter logic [17:0] INPUT_HEX_VALUE  = 18'h3FFFF;  // 262143 decimal
  parameter logic [31:0] EXPECTED_BCD_OUT = 32'h51199902; // Correct BCD

  // ---------------- Dual-issue monitors ----------------
  logic [11:0] pc_fetch_prev;
  logic        pc_prev_valid;

  // Monitor fetch PC stride matches issue count when no control redirect
  always_ff @(posedge CLOCK_50) begin
    if (KEY[0] == 1'b0) begin
      pc_prev_valid <= 1'b0;
    end else begin
      if (pc_prev_valid && !dut.cpu0.flush_EX) begin
        logic [11:0] expected_stride;
        expected_stride = dut.cpu0.slot1_issue_F ? 12'd2 : 12'd1;
        if (dut.cpu0.pc_F != pc_fetch_prev + expected_stride) begin
          $error("PC stride mismatch: prev=%0d curr=%0d expected_stride=%0d (slot1_issue=%0b)",
                 pc_fetch_prev, dut.cpu0.pc_F, expected_stride, dut.cpu0.slot1_issue_F);
        end
      end
      pc_fetch_prev <= dut.cpu0.pc_F;
      pc_prev_valid <= 1'b1;
    end
  end

  // Verify fetched instruction pairs map correctly to 64-bit instmem entries
  always_ff @(posedge CLOCK_50) begin
    if (KEY[0] && !dut.cpu0.flush_EX) begin
      logic [63:0] line_curr;
      logic [63:0] line_next;
      logic [31:0] expected_even;
      logic [31:0] expected_odd;
      line_curr = dut.cpu0.instmem[dut.cpu0.pc_F[11:1]];
      line_next = dut.cpu0.instmem[dut.cpu0.pc_F[11:1] + 12'd1];
      if (dut.cpu0.pc_F[0] == 1'b0) begin
        expected_even = line_curr[31:0];
        expected_odd  = line_curr[63:32];
      end else begin
        expected_even = line_curr[63:32];
        expected_odd  = line_next[31:0];
      end

      if (dut.cpu0.instr0_F !== expected_even) begin
        $error("Fetch mismatch even slot: PC=%0d expected=%h got=%h",
               dut.cpu0.pc_F, expected_even, dut.cpu0.instr0_F);
      end
      if (dut.cpu0.slot1_issue_F && (dut.cpu0.instr1_F !== expected_odd)) begin
        $error("Fetch mismatch odd slot: PC=%0d expected=%h got=%h",
               dut.cpu0.pc_F + 12'd1, expected_odd, dut.cpu0.instr1_F);
      end
    end
  end
  
  // Instantiate DUT (top) - ALL PORTS MAPPED
  top dut (
    .CLOCK_50  (CLOCK_50),
    .CLOCK2_50 (CLOCK2_50),
    .CLOCK3_50 (CLOCK3_50),
    .LEDG      (LEDG),
    .LEDR      (LEDR),
    .KEY       (KEY),
    .SW        (SW),
    .HEX0      (HEX0),
    .HEX1      (HEX1),
    .HEX2      (HEX2),
    .HEX3      (HEX3),
    .HEX4      (HEX4),
    .HEX5      (HEX5),
    .HEX6      (HEX6),
    .HEX7      (HEX7)
  );
  
  // ---------------- clock generation ----------------
  initial begin
    CLOCK_50  = 0;
    CLOCK2_50 = 0;
    CLOCK3_50 = 0;
    forever #10 begin
      CLOCK_50  = ~CLOCK_50;
      CLOCK2_50 = ~CLOCK2_50;
      CLOCK3_50 = ~CLOCK3_50;
    end
  end
  
  // ---------------- main test sequence ----------------
  initial begin
    $timeformat(-9, 1, " ns", 10);
    $display("--- Test Start ---");
    
    // initial defaults
    KEY = 4'b1111; 
    SW  = 18'h00000;
    #20;
    
    // Apply reset: KEY[0] = 0
    $display("Applying reset (KEY[0]=0)...");
    KEY[0] = 1'b0;
    #20;
    
    // Set input value on switches
    SW = INPUT_HEX_VALUE;
    $display("Input Binary Value (SW/io0): 0x%h (%0d)", INPUT_HEX_VALUE, INPUT_HEX_VALUE);
    #20;
    
    // Release reset: KEY[0] = 1
    KEY[0] = 1'b1;
    $display("Releasing reset (KEY[0]=1). CPU starts execution.");
    
    // Wait for CPU to execute the assembled program.
    #8000; // 8000 ns (~400 cycles @50MHz)
    
    $display("--- Test End ---");
    $display("Final BCD Output (dut.cpu0.gpio_out) = 0x%08h", dut.cpu0.gpio_out);

    // Decode the output for easier reading
    $display("  HEX7 (ten-millions):     %h", dut.cpu0.gpio_out[31:28]);
    $display("  HEX6 (millions):         %h", dut.cpu0.gpio_out[27:24]);
    $display("  HEX5 (hundred-thousands): %h", dut.cpu0.gpio_out[23:20]);
    $display("  HEX4 (ten-thousands):    %h", dut.cpu0.gpio_out[19:16]);
    $display("  HEX3 (thousands):        %h", dut.cpu0.gpio_out[15:12]);
    $display("  HEX2 (hundreds):         %h", dut.cpu0.gpio_out[11:8]);
    $display("  HEX1 (tens):             %h", dut.cpu0.gpio_out[7:4]);
    $display("  HEX0 (ones):             %h", dut.cpu0.gpio_out[3:0]);
    
    if (dut.cpu0.gpio_out == EXPECTED_BCD_OUT) begin
      $display("TEST PASSED: The BCD result 0x%08h is correct.", dut.cpu0.gpio_out);
    end else begin
      $display("TEST FAILED: Expected 0x%08h, Got: 0x%08h", EXPECTED_BCD_OUT, dut.cpu0.gpio_out);
    end
    
    $display("\n----REGDUMP----");
    for (int i = 0; i < 32; i++) begin
      if (dut.cpu0.rf.mem[i] != 32'd0) begin
        $display("  REGISTER x%02d = 0x%08h (%0d) \n", i, dut.cpu0.rf.mem[i], $signed(dut.cpu0.rf.mem[i]));
      end
    end 
    $display("---------------");
    $finish;
  end
endmodule
