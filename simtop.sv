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
  // Input (Binary): 0x0002D687 = 185,991 decimal
  // BCD representation: 0 0 1 8 5 9 9 1 (reading HEX7→HEX0)
  // With HEX0 at bits 28-31, HEX7 at bits 0-3:
  // Expected: 0x19958100
  //   bits 28-31: 1 (HEX0 - ones)
  //   bits 24-27: 9 (HEX1 - tens)
  //   bits 20-23: 9 (HEX2 - hundreds)
  //   bits 16-19: 5 (HEX3 - thousands)
  //   bits 12-15: 8 (HEX4 - ten-thousands)
  //   bits  8-11: 1 (HEX5 - hundred-thousands)
  //   bits  4-7:  0 (HEX6 - millions)
  //   bits  0-3:  0 (HEX7 - ten-millions)
  
  parameter logic [17:0] INPUT_HEX_VALUE  = 18'h2D687;  // 185991 decimal
  parameter logic [31:0] EXPECTED_BCD_OUT = 32'h19958100; // Correct BCD
  
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
    #4000; // 4000 ns (~200 cycles @50MHz)
    
    $display("--- Test End ---");
    $display("Final BCD Output (dut.cpu0.gpio_out) = 0x%08h", dut.cpu0.gpio_out);
    
    // Decode the output for easier reading
    $display("  HEX7 (ten-millions):     %h", dut.cpu0.gpio_out[3:0]);
    $display("  HEX6 (millions):         %h", dut.cpu0.gpio_out[7:4]);
    $display("  HEX5 (hundred-thousands): %h", dut.cpu0.gpio_out[11:8]);
    $display("  HEX4 (ten-thousands):    %h", dut.cpu0.gpio_out[15:12]);
    $display("  HEX3 (thousands):        %h", dut.cpu0.gpio_out[19:16]);
    $display("  HEX2 (hundreds):         %h", dut.cpu0.gpio_out[23:20]);
    $display("  HEX1 (tens):             %h", dut.cpu0.gpio_out[27:24]);
    $display("  HEX0 (ones):             %h", dut.cpu0.gpio_out[31:28]);
    
    if (dut.cpu0.gpio_out == EXPECTED_BCD_OUT) begin
      $display("TEST PASSED: The BCD result 0x%08h is correct.", dut.cpu0.gpio_out);
    end else begin
      $display("TEST FAILED: Expected 0x%08h, Got: 0x%08h", EXPECTED_BCD_OUT, dut.cpu0.gpio_out);
    end
    
    $finish;
  end
endmodule
