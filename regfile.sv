/* 32 x 32 register file implementation */

module regfile (

/**** inputs *****************************************************************/

	input logic [0:0 ] clk,		/* clock */
	input logic [0:0 ] we,		/* write enable slot 0 */
	input logic [0:0 ] we2,		/* write enable slot 1 */
	input logic [4:0 ] readaddr1,		/* read address 1 */
	input logic [4:0 ] readaddr2,		/* read address 2 */
	input logic [4:0 ] readaddr3,		/* read address 3 */
	input logic [4:0 ] readaddr4,		/* read address 4 */
	input logic [4:0 ] writeaddr,		/* write address slot 0 */
	input logic [4:0 ] writeaddr2,		/* write address slot 1 */
	input logic [31:0] writedata,		/* write data slot 0 */
	input logic [31:0] writedata2,		/* write data slot 1 */

/**** outputs ****************************************************************/

	output logic [31:0] readdata1,	/* read data 1 */
	output logic [31:0] readdata2,		/* read data 2 */
	output logic [31:0] readdata3,		/* read data 3 */
	output logic [31:0] readdata4		/* read data 4 */
);

// REGS
(* ramstyle = "M9K" *) logic [31:0] mem[31:0];

always_ff @(posedge clk) begin
	if (we && writeaddr != 5'd0) begin
		mem[writeaddr] <= writedata;
	end
	if (we2 && writeaddr2 != 5'd0) begin
		mem[writeaddr2] <= writedata2;
	end
end

always_comb begin
	// $monitor("reg 6: %8h", mem[6]);
	// $monitor("reg 5: %8h", mem[5]);
	// $monitor("writeaddr: %8h, we: %1h", writeaddr, we);

	if (readaddr1 == 5'd0) readdata1 = 32'd0;
	else if (we && readaddr1 == writeaddr) readdata1 = writedata;
	else if (we2 && readaddr1 == writeaddr2) readdata1 = writedata2;
	else readdata1 = mem[readaddr1];

	if (readaddr2 == 5'd0) readdata2 = 32'd0;
	else if (we && readaddr2 == writeaddr) readdata2 = writedata;
	else if (we2 && readaddr2 == writeaddr2) readdata2 = writedata2;
	else readdata2 = mem[readaddr2];

	if (readaddr3 == 5'd0) readdata3 = 32'd0;
	else if (we && readaddr3 == writeaddr) readdata3 = writedata;
	else if (we2 && readaddr3 == writeaddr2) readdata3 = writedata2;
	else readdata3 = mem[readaddr3];

	if (readaddr4 == 5'd0) readdata4 = 32'd0;
	else if (we && readaddr4 == writeaddr) readdata4 = writedata;
	else if (we2 && readaddr4 == writeaddr2) readdata4 = writedata2;
	else readdata4 = mem[readaddr4];
end

endmodule
