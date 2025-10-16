// -----------------------------------------------------------------------------
// hexdriver.sv
// Renders a 4-bit nibble (0–F) to a 7-segment display pattern.
// Compatible with DE2-115 board HEX displays (active-low segments).
// -----------------------------------------------------------------------------

module hexdriver (
    input  logic [3:0] nibble,   // 4-bit nibble input
    output logic [6:0] seg       // 7-segment output {a,b,c,d,e,f,g}
);

    always_comb begin
        case (nibble)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0001000; // A
            4'hB: seg = 7'b0000011; // b
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0100001; // d
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // all segments off
        endcase
    end

endmodule


