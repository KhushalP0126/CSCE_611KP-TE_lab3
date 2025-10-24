// control_unit.sv
// Simple combinational control unit for the lab subset:
// R-type (arithmetic), I-type (arithmetic + shifts), LUI, CSRRW (CSR read/write).
// Outputs: alusrc, regwrite, regsel, aluop, csr_addr.

module control_unit (
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    input  logic [1:0]  instr_type,   // from decoder
    input  logic [11:0] csr_imm,      // instr[31:20] when CSR present

    output logic        alusrc,       // 0 = rs2, 1 = imm/shamt
    output logic        regwrite,     // write register file
    output logic [1:0]  regsel,       // 00=ALU,01=CSR readback,10=U-immediate
    output logic [3:0]  aluop,        // ALU opcode (matches alu.sv encoding assumed)
    output logic [11:0] csr_addr,
    output logic        csr_we,       // assert on CSRRW to write CSRs
    output logic        gpio_we       // assert when CSRRW targets GPIO out
);

    // Memory-mapped CSR addresses used for GPIO interaction
    localparam logic [11:0] CSR_GPIO_IN   = 12'hF00;
    localparam logic [11:0] CSR_GPIO_OUT0 = 12'hF02;
    localparam logic [11:0] CSR_GPIO_OUT1 = 12'hF03;

    always_comb begin
        // defaults
        alusrc   = 1'b0;
        regwrite = 1'b0;
        regsel   = 2'b00;
        aluop    = 4'b0011; // default ADD
        csr_addr = csr_imm;
        csr_we   = 1'b0;
        gpio_we  = 1'b0;

        unique case (opcode)
            7'b0110011: begin // R-type
                alusrc   = 1'b0;
                regwrite = 1'b1;
                regsel   = 2'b00;
                case ({funct7, funct3})
                    {7'b0000000,3'b000}: aluop = 4'b0011; // ADD
                    {7'b0100000,3'b000}: aluop = 4'b0100; // SUB
                    {7'b0000000,3'b111}: aluop = 4'b0000; // AND
                    {7'b0000000,3'b110}: aluop = 4'b0001; // OR
                    {7'b0000000,3'b100}: aluop = 4'b0010; // XOR
                    {7'b0000000,3'b001}: aluop = 4'b1000; // SLL
                    {7'b0000000,3'b101}: aluop = 4'b1001; // SRL
                    {7'b0100000,3'b101}: aluop = 4'b1010; // SRA
                    {7'b0000000,3'b010}: aluop = 4'b1100; // SLT
                    {7'b0000000,3'b011}: aluop = 4'b1101; // SLTU
                    {7'b0000001,3'b000}: aluop = 4'b0101; // MUL
                    {7'b0000001,3'b001}: aluop = 4'b0110; // MULH
                    {7'b0000001,3'b011}: aluop = 4'b0111; // MULHU
                    default: aluop = 4'b0011;
                endcase
            end

            7'b0010011: begin // I-type arithmetic / shifts
                alusrc   = 1'b1;
                regwrite = 1'b1;
                regsel   = 2'b00;
                case (funct3)
                    3'b000: aluop = 4'b0011; // ADDI
                    3'b111: aluop = 4'b0000; // ANDI
                    3'b110: aluop = 4'b0001; // ORI
                    3'b100: aluop = 4'b0010; // XORI
                    3'b001: aluop = 4'b1000; // SLLI (shamt)
                    3'b101: begin // SRLI / SRAI
                        if (funct7 == 7'b0000000) aluop = 4'b1001;
                        else                     aluop = 4'b1010;
                    end
                    default: aluop = 4'b0011;
                endcase
            end

            7'b0110111: begin // LUI (U-type)
                alusrc   = 1'b1;
                regwrite = 1'b1;
                regsel   = 2'b10; // U-immediate
                aluop    = 4'b0011;
            end

            7'b1110011: begin // CSRRW (approx)
                if (funct3 == 3'b001) begin
                    regwrite = 1'b1;   // write old CSR value to rd
                    regsel   = 2'b01;  // select CSR readback for writeback
                    csr_we   = 1'b1;
                    if (csr_imm == CSR_GPIO_OUT0 || csr_imm == CSR_GPIO_OUT1) begin
                        gpio_we = 1'b1;
                    end
                end
            end

            default: begin
                // do nothing (safe defaults)
            end
        endcase
    end

endmodule
