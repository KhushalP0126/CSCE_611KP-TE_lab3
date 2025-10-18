// simtop.sv - Testbench matching all ports of the top.sv file

module simtop;

  // --- clocks (as in top.sv) ---
  logic CLOCK_50;
  logic CLOCK2_50; // <-- RESTORED
  logic CLOCK3_50; // <-- RESTORED

  // --- LEDs widths matching top.sv ---
  logic [8:0]  LEDG; // <-- RESTORED
  logic [17:0] LEDR; // <-- RESTORED

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
  // Input (Binary): 0x0012D687 (1234567 decimal). Note: 18'h2D687 is 184135 decimal. 
  // We'll revert to 1234567 (0x12D687) as that's a common example for BCD
  // Let's use 1234567 decimal = 0x12D687 (24 bits, but we use 18-bit SW width).
  // Assuming the `bin2dec.asm` only uses the lower 18 bits from `SW`.
  // 184,135 decimal = 0x02D687 (fits in 18 bits) -> BCD output: 0x00184135
  parameter logic [17:0] INPUT_HEX_VALUE  = 18'h2D687;
  parameter logic [31:0] EXPECTED_BCD_OUT = 32'h00184135;

  // Instantiate DUT (top) - ALL PORTS MAPPED
  top dut (
    .CLOCK_50  (CLOCK_50),
    .CLOCK2_50 (CLOCK2_50), // <-- CONNECTION RESTORED
    .CLOCK3_50 (CLOCK3_50), // <-- CONNECTION RESTORED
    .LEDG      (LEDG),      // <-- CONNECTION RESTORED
    .LEDR      (LEDR),      // <-- CONNECTION RESTORED
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
  // 50 MHz => 20 ns period => toggle every 10 ns
  initial begin
    CLOCK_50  = 0;
    CLOCK2_50 = 0; // Initialize
    CLOCK3_50 = 0; // Initialize
    forever #10 begin
      CLOCK_50  = ~CLOCK_50;
      CLOCK2_50 = ~CLOCK2_50; // Toggle
      CLOCK3_50 = ~CLOCK3_50; // Toggle
    end
  end

  // ---------------- main test sequence ----------------
  initial begin
    $timeformat(-9, 1, " ns", 10);
    $display("--- Test Start ---");

    // initial defaults
    KEY = 4'b1111; 
    SW  = 32'h00000;

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
    #4000; // 4000 ns (~200 cycles @50MHz)

    $display("--- Test End ---");
    
    // Read the GPIO output from the CPU instance inside top.
    $display("Final BCD Output (dut.cpu0.gpio_out) = 0x%08h", dut.cpu0.gpio_out);

    if (dut.cpu0.gpio_out == EXPECTED_BCD_OUT) begin
      $display("TEST PASSED: The BCD result 0x%08h is correct.", dut.cpu0.gpio_out);
    end else begin
      $display("TEST FAILED: Expected 0x%08h, Got: 0x%08h", EXPECTED_BCD_OUT, dut.cpu0.gpio_out);
    end

    $finish;
  end

endmodule
