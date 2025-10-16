// top.sv
// Top-level that instantiates the CPU and drives the 8 seven-seg displays.
// Replaces the original top and wires CLOCK_50, KEY, SW, HEX0..HEX7 as requested.

module top (

        //////////// CLOCK //////////
        input                                   CLOCK_50,
        input                                   CLOCK2_50,
        input                                   CLOCK3_50,

        //////////// LED //////////
        output               [8:0]              LEDG,
        output              [17:0]              LEDR,

        //////////// KEY //////////
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

    //=======================================================
    //  REG/WIRE declarations (LED animation)
    //=======================================================
    logic [23:0] clkdiv;
    logic ledclk;

    /* driver for LEDs */
    logic [25:0] leds;
    logic ledstate;

    assign ledclk = clkdiv[23];
    assign LEDR = leds[25:8];
    assign LEDG = leds[7:0];

    initial begin
        clkdiv = 26'h0;
        /* start at the far right, LEDG0 */
        leds = 26'b1;
        /* start out going to the left */
        ledstate = 1'b0;
    end

    always @(posedge CLOCK_50) begin
        clkdiv <= clkdiv + 1;
    end

    always @(posedge ledclk) begin
        if ( (ledstate == 0) && (leds == 26'b10000000000000000000000000) ) begin
            ledstate <= 1;
            leds <= leds >> 1;
        end else if (ledstate == 0) begin
            ledstate <= 0;
            leds <= leds << 1;
        end else if ( (ledstate == 1) && (leds == 26'b1) ) begin
            ledstate <= 0;
            leds <= leds << 1;
        end else begin
            leds <= leds >> 1;
        end
    end

    //=======================================================
    //  CPU instantiation and HEX driving
    //=======================================================
    logic [31:0] cpu_gpio_in;
    logic [31:0] cpu_gpio_out;

    // Map switches into lower 18 bits of gpio_in (zero-extend upper bits)
    assign cpu_gpio_in = {14'd0, SW};

    // Reset: board KEY[0] is active-low pushbutton. CPU expects active-high rst.
    // So assert rst when KEY[0] == 0 (pressed).
    cpu cpu0 (
        .clk      (CLOCK_50),
        .rst      (~KEY[0]),
        .gpio_in  (cpu_gpio_in),
        .gpio_out (cpu_gpio_out)
    );

    // Split cpu_gpio_out into 8 nibbles for HEX0..HEX7
    wire [3:0] nib0 = cpu_gpio_out[3:0];
    wire [3:0] nib1 = cpu_gpio_out[7:4];
    wire [3:0] nib2 = cpu_gpio_out[11:8];
    wire [3:0] nib3 = cpu_gpio_out[15:12];
    wire [3:0] nib4 = cpu_gpio_out[19:16];
    wire [3:0] nib5 = cpu_gpio_out[23:20];
    wire [3:0] nib6 = cpu_gpio_out[27:24];
    wire [3:0] nib7 = cpu_gpio_out[31:28];

    // Instantiate hexdriver modules (one per 7-seg)
    // If your hexdriver module uses different port names, update these instances.
    hexdriver hd0 (.nibble(nib0), .seg(HEX0));
    hexdriver hd1 (.nibble(nib1), .seg(HEX1));
    hexdriver hd2 (.nibble(nib2), .seg(HEX2));
    hexdriver hd3 (.nibble(nib3), .seg(HEX3));
    hexdriver hd4 (.nibble(nib4), .seg(HEX4));
    hexdriver hd5 (.nibble(nib5), .seg(HEX5));
    hexdriver hd6 (.nibble(nib6), .seg(HEX6));
    hexdriver hd7 (.nibble(nib7), .seg(HEX7));

endmodule
