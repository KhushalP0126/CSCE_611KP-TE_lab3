// regfile.sv
// 32 x 32 register file
// Ports:
//   input        clk
//   input        we          - write enable (1 bit)
//   input  [4:0] readaddr1
//   input  [4:0] readaddr2
//   input  [4:0] writeaddr
//   input  [31:0] writedata
//   output [31:0] readdata1
//   output [31:0] readdata2
//
// Reads are combinational; writes occur on posedge clk.
// Register x0 is hard-wired to 0.

module regfile (
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  readaddr1,
    input  logic [4:0]  readaddr2,
    input  logic [4:0]  writeaddr,
    input  logic [31:0] writedata,

    output logic [31:0] readdata1,
    output logic [31:0] readdata2
);

    // 32 registers (x0..x31)
    logic [31:0] regs [31:0];

    // Write port (x0 is read-only zero)
    always_ff @(posedge clk) begin
        if (we) begin
            if (writeaddr != 5'd0) begin
                regs[writeaddr] <= writedata;
            end
            // ignore writes to x0
        end
    end

    // Combinational read ports
    // Read port 1
    always_comb begin
        if (readaddr1 == 5'd0) readdata1 = 32'd0;
        else readdata1 = regs[readaddr1];
    end

    // Read port 2
    always_comb begin
        if (readaddr2 == 5'd0) readdata2 = 32'd0;
        else readdata2 = regs[readaddr2];
    end

endmodule

