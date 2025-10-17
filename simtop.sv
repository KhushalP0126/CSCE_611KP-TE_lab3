// simtop.sv - minimal testbench matched to your top.sv ports
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

  // Instantiate DUT using named port mapping (avoids ordering mistakes)
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

  // ---------------- clocks ----------------
  // 50 MHz => 20 ns period => toggle every 10 ns
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

  // ---------------- reset & inputs ----------------
  initial begin
    // defaults
    KEY = 4'b1111;
    SW  = 18'h00000;

    // small settle, then pulse reset on KEY[0] (active-low on DE2)
    #5;
    KEY[0] = 1'b0;   // press KEY0 (assert reset if top uses ~KEY[0])
    #100;
    KEY[0] = 1'b1;   // release reset
  end

  // ---------------- optional test actions ----------------
  initial begin
    #200;              // wait for reset to release
    SW = 18'd123;      // example switch value (change as needed)
    #2000;
    // Print a small summary so you can see values in transcript
    $display("simtop: stopping simulation. LEDR=%b LEDG=%b HEX0=%b HEX1=%b",
             LEDR, LEDG, HEX0, HEX1);
    $stop;
  end

endmodule

