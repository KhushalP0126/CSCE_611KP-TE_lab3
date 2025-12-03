// top.sv
// Top-level that instantiates the CPU and drives the 8 seven-seg displays.
// Reset / KEY signals are treated as ACTIVE-LOW throughout this file.

module top (
    //////////// CLOCK //////////
    input                                   CLOCK_50,
    input                                   CLOCK2_50,
    input                                   CLOCK3_50,

    //////////// LED //////////
    output               [8:0]              LEDG,
    output              [17:0]              LEDR,

    //////////// KEY //////////
    // NOTE: DE2 pushbuttons (KEY) are active-low when pressed.
    input                [3:0]              KEY,

    //////////// SW //////////
    input               [17:0]              SW,

    //////////// SEG7 //////////
    output               [6:0]              HEX0,
    output               [6:0]              HEX1,
    output               [6:0]              HEX2,
    output               [6:0]              HEX3,
    output               [6:0]              HEX4,
    output               [6:0]              HEX5,
    output               [6:0]              HEX6,
    output               [6:0]              HEX7
);

    // ---------------------------------------------------------------------
    // Internal signals
    // ---------------------------------------------------------------------
    // cpu_gpio_out is driven by cpu (32-bit). We'll display its 8 nibbles on HEX0..HEX7.
    logic [31:0] cpu_gpio_out;

    // If you have other modules that expected an active-high reset, they should
    // now be updated to treat reset as active-low as well (i.e., assert when 0).
    // Here we wire KEY[0] directly as an active-low reset.
    // Pressing KEY[0] (makes it 0) will assert reset.
    wire rst_n = KEY[0]; // active-low reset signal (rst_n == 0 means reset asserted)

    // ---------------------------------------------------------------------
    // Instantiate CPU
    // ---------------------------------------------------------------------
    // IMPORTANT: This cpu instance now expects an active-low reset input.
    // That means within cpu.sv your cpu module should treat rst as active-low.
    // Example: if (rst_n == 1'b0) begin /* reset logic */ end
    cpu cpu0 (
        .clk      (CLOCK_50),           // 50 MHz clock
        .rst      (rst_n),              // active-low reset: KEY[0] pressed -> rst=0 -> reset asserted
        .gpio_in  ({14'b0, SW}),        // extend SW[17:0] to 32 bits (upper bits zero)
        .gpio_out (cpu_gpio_out)        // 32-bit gpio -> map to HEX displays
    );

    // ---------------------------------------------------------------------
    // Drive the HEX displays: break cpu_gpio_out into 8 nibbles
    // ---------------------------------------------------------------------
    // If your hexdriver module has different port names, adapt the instance ports.
    // Here each hexdriver instance converts a 4-bit nibble to a 7-bit segment vector.
    // Map nibble 0 -> HEX0 (ones) up through nibble 7 -> HEX7 (MSD)
    hexdriver hd0  (.in(cpu_gpio_out[ 3: 0]), .out(HEX0));
    hexdriver hd1  (.in(cpu_gpio_out[ 7: 4]), .out(HEX1));
    hexdriver hd2  (.in(cpu_gpio_out[11: 8]), .out(HEX2));
    hexdriver hd3  (.in(cpu_gpio_out[15:12]), .out(HEX3));
    hexdriver hd4  (.in(cpu_gpio_out[19:16]), .out(HEX4));
    hexdriver hd5  (.in(cpu_gpio_out[23:20]), .out(HEX5));
    hexdriver hd6  (.in(cpu_gpio_out[27:24]), .out(HEX6));
    hexdriver hd7  (.in(cpu_gpio_out[31:28]), .out(HEX7));

    // ---------------------------------------------------------------------
    // Optional: tie unused LEDs off (or hook to other signals you like)
    // ---------------------------------------------------------------------
    assign LEDG = 9'd0;
    assign LEDR = 18'd0;

endmodule
