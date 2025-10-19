// simtop.sv - Exhaustive verification testbench for top.sv

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

  // --- 7-seg displays matching top.sv ---
  logic [6:0] HEX0;
  logic [6:0] HEX1;
  logic [6:0] HEX2;
  logic [6:0] HEX3;
  logic [6:0] HEX4;
  logic [6:0] HEX5;
  logic [6:0] HEX6;
  logic [6:0] HEX7;

  // Packed BCD layout produced by firmware:
  //   HEX0 (ones)            -> bits [31:28]
  //   HEX1 (tens)            -> bits [27:24]
  //   HEX2 (hundreds)        -> bits [23:20]
  //   HEX3 (thousands)       -> bits [19:16]
  //   HEX4 (ten-thousands)   -> bits [15:12]
  //   HEX5 (hundred-thousands)-> bits [11:8]
  //   HEX6 (millions)        -> bits [7:4]
  //   HEX7 (ten-millions)    -> bits [3:0]

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
    CLOCK_50  = 1'b0;
    CLOCK2_50 = 1'b0;
    CLOCK3_50 = 1'b0;
    forever #10 begin
      CLOCK_50  = ~CLOCK_50;
      CLOCK2_50 = ~CLOCK2_50;
      CLOCK3_50 = ~CLOCK3_50;
    end
  end

  // ---------------- reference conversion ----------------
  function automatic logic [31:0] reference_bcd(input logic [17:0] value);
    logic [31:0] tmp;
    logic [31:0] quotient;
    logic [3:0]  digit;
    reference_bcd = 32'd0;
    tmp = value;
    for (int i = 0; i < 8; i++) begin
      quotient = tmp / 10;
      digit    = tmp - quotient * 10;
      reference_bcd |= (digit << (28 - (i * 4)));
      tmp = quotient;
    end
  endfunction

  // Run the DUT for a single switch setting
  task automatic run_single_case(input logic [17:0] sw_value, output bit pass);
    logic [31:0] expected;
    logic [31:0] observed;

    KEY    = 4'b1111;
    KEY[0] = 1'b0;
    SW     = sw_value;
    repeat (2) @(posedge CLOCK_50);

    KEY[0] = 1'b1;
    repeat (200) @(posedge CLOCK_50);

    observed = dut.cpu0.gpio_out;
    expected = reference_bcd(sw_value);

    pass = (observed === expected);
    if (!pass) begin
      $error("Mismatch: SW=0x%05h expected=0x%08h observed=0x%08h",
             sw_value, expected, observed);
    end
  endtask

  // ---------------- exhaustive sweep ----------------
  initial begin
    bit ok;
    $timeformat(-9, 1, " ns", 10);
    $display("--- Exhaustive Test Start ---");

    KEY = 4'b1111;
    SW  = '0;
    @(posedge CLOCK_50);

    for (int unsigned value = 0; value < (1 << 18); value++) begin
      run_single_case(value[17:0], ok);
      if (!ok) begin
        $display("Stopping after failure at SW=0x%05h", value[17:0]);
        $finish;
      end
    end

    $display("--- Exhaustive Test End: all %0d cases passed ---", 1 << 18);
    $finish;
  end
endmodule
