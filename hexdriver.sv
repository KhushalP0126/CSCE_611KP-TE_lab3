// -----------------------------------------------------------------------------
// hexdriver.sv
// Renders a 4-bit nibble (0–F) to a 7-segment display pattern.
// Compatible with DE2-115 board HEX displays (active-low segments).
// -----------------------------------------------------------------------------

module hexdriver (
    input  logic [3:0] in,    // 4-bit nibble input (named 'in' to match top.sv)
    output logic [6:0] out    // 7-segment output {a,b,c,d,e,f,g} (active-low)
);

    // Map nibble -> active-low 7-seg pattern. '0' means segment driven low (on).
    always_comb begin
        case (in)
            4'h0: out = 7'b1000000; // 0
            4'h1: out = 7'b1111001; // 1
            4'h2: out = 7'b0100100; // 2
            4'h3: out = 7'b0110000; // 3
            4'h4: out = 7'b0011001; // 4
            4'h5: out = 7'b0010010; // 5
            4'h6: out = 7'b0000010; // 6
            4'h7: out = 7'b1111000; // 7
            4'h8: out = 7'b0000000; // 8
            4'h9: out = 7'b0010000; // 9
            4'hA: out = 7'b0001000; // A
            4'hB: out = 7'b0000011; // b
            4'hC: out = 7'b1000110; // C
            4'hD: out = 7'b0100001; // d
            4'hE: out = 7'b0000110; // E
            4'hF: out = 7'b0001110; // F
            default: out = 7'b1111111; // all segments off (inactive - high)
        endcase
    end

endmodule

