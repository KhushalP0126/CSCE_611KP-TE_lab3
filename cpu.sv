// cpu.sv - modified for active-low asynchronous reset (rst is active LOW)
// 3-stage pipeline CPU (F -> EX -> WB) implementing a small RV32I subset.
// Connects to external ALU, regfile and CSR I/O (gpio_in / gpio_out).
//
// Now: rst is ACTIVE-LOW (asserted when rst == 1'b0).
//
// Assumptions (if your module uses different port names, adapt the instance port names):
//  - alu.sv ports: A, B, op, R, zero
//  - regfile.sv ports: clk, we, readaddr1, readaddr2, writeaddr, writedata, readdata1, readdata2
//  - instmem is loaded from "instmem.dat" (hex words), 4096 words

module cpu (
    input  logic        clk,        // CLOCK_50 from top
    input  logic        rst,        // ACTIVE-LOW reset (asserted when rst==0)
    input  logic [31:0] gpio_in,    // e.g. switches -> CSR read (io0)
    output logic [31:0] gpio_out    // e.g. HEX output driver -> CSR write (io2/io3)
);

    // instruction memory (4096 x 32)
    logic [31:0] instmem [4095:0];
    initial $readmemh("instmem.dat", instmem);

    // Program counter (word addressed)
    logic [11:0] pc_F;
    // active-low asynchronous reset: sensitive to negedge rst
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) pc_F <= 12'd0;
        else      pc_F <= pc_F + 12'd1;
    end

    // Fetch register (synchronous memory read)
    logic [31:0] instr_F;
    always_ff @(posedge clk) instr_F <= instmem[pc_F];

    // EX-stage register: instruction register
    logic [31:0] instr_EX;
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) instr_EX <= 32'd0;
        else      instr_EX <= instr_F;
    end

    // ---- decoder outputs in EX stage ----
    logic [6:0]  opcode_EX;
    logic [6:0]  funct7_EX;
    logic [2:0]  funct3_EX;
    logic [4:0]  rd_EX, rs1_EX, rs2_EX;
    logic [31:0] imm_i_EX, imm_u_EX;
    logic [4:0]  shamt_EX;
    logic [1:0]  instr_type_EX;

    instruction_decoder id (
        .instr(instr_EX),
        .opcode(opcode_EX),
        .funct7(funct7_EX),
        .funct3(funct3_EX),
        .rd(rd_EX),
        .rs1(rs1_EX),
        .rs2(rs2_EX),
        .imm_i(imm_i_EX),
        .imm_u(imm_u_EX),
        .shamt(shamt_EX),
        .instr_type(instr_type_EX)
    );

    // ---- control signals in EX stage ----
    logic        alusrc_EX;
    logic        regwrite_EX;
    logic [1:0]  regsel_EX;
    logic [3:0]  aluop_EX;
    logic        gpio_we_EX;
    logic [11:0] csr_addr_EX;

    control_unit cu (
        .opcode(opcode_EX),
        .funct3(funct3_EX),
        .funct7(funct7_EX),
        .instr_type(instr_type_EX),
        .csr_imm(instr_EX[31:20]),

        .alusrc(alusrc_EX),
        .regwrite(regwrite_EX),
        .regsel(regsel_EX),
        .aluop(aluop_EX),
        .gpio_we(gpio_we_EX),
        .csr_addr(csr_addr_EX)
    );

    // ---- register file (external) ----
    logic [31:0] rf_readdata1_EX, rf_readdata2_EX;
    logic        rf_we_WB;
    logic [4:0]  rf_writeaddr_WB;
    logic [31:0] rf_writedata_WB;

    regfile rf (
        .clk        (clk),
        .we         (rf_we_WB),
        .readaddr1  (rs1_EX),
        .readaddr2  (rs2_EX),
        .writeaddr  (rf_writeaddr_WB),
        .writedata  (rf_writedata_WB),
        .readdata1  (rf_readdata1_EX),
        .readdata2  (rf_readdata2_EX)
    );

    // ---- ALU inputs selection ----
    logic [31:0] alu_A_EX, alu_B_EX;
    logic [31:0] imm_shamt_EXT;
    assign alu_A_EX = rf_readdata1_EX;

    // if shift-immediate, use shamt; else use imm_i
    assign imm_shamt_EXT = ((instr_type_EX == 2'b01) && (funct3_EX == 3'b001 || funct3_EX == 3'b101))
                           ? {{27{1'b0}}, shamt_EX}
                           : imm_i_EX;
    assign alu_B_EX = (alusrc_EX) ? imm_shamt_EXT : rf_readdata2_EX;

    // ALU (assumed ports: A,B,op,R,zero). If your alu uses different names adjust instance
    logic [31:0] alu_R_EX;
    logic        alu_zero_EX;

    alu the_alu (
        .A (alu_A_EX),
        .B (alu_B_EX),
        .op(aluop_EX),
        .R (alu_R_EX),
        .zero(alu_zero_EX)
    );

    // ---- EX -> WB registers ----
    logic [31:0] alu_result_WB;
    logic [31:0] csr_read_WB;
    logic [4:0]  rd_WB;
    logic [1:0]  regsel_WB;
    logic        regwrite_WB;
    logic [31:0] imm_u_EX_reg;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            alu_result_WB <= 32'd0;
            csr_read_WB   <= 32'd0;
            rd_WB         <= 5'd0;
            regsel_WB     <= 2'b00;
            regwrite_WB   <= 1'b0;
            imm_u_EX_reg  <= 32'd0;
        end else begin
            alu_result_WB <= alu_R_EX;
            // CSR readback mapping (simple):
            if (opcode_EX == 7'b1110011 && funct3_EX == 3'b001) begin
                case (csr_addr_EX)
                    12'hF00: csr_read_WB <= gpio_in; // io0 -> switches
                    default: csr_read_WB <= 32'd0;
                endcase
            end else csr_read_WB <= 32'd0;

            rd_WB       <= rd_EX;
            regsel_WB   <= regsel_EX;
            regwrite_WB <= regwrite_EX;
            imm_u_EX_reg<= imm_u_EX;
        end
    end

    // ---- Writeback selection ----
    always_comb begin
        unique case (regsel_WB)
            2'b00: rf_writedata_WB = alu_result_WB;
            2'b01: rf_writedata_WB = csr_read_WB;
            2'b10: rf_writedata_WB = imm_u_EX_reg;
            default: rf_writedata_WB = alu_result_WB;
        endcase
    end

    // register file write control (registered on posedge)
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            rf_we_WB <= 1'b0;
            rf_writeaddr_WB <= 5'd0;
        end else begin
            rf_we_WB <= regwrite_WB;
            rf_writeaddr_WB <= rd_WB;
        end
    end

    // ---- CSR / GPIO writes (handle writes to io2/io3 -> gpio_out) ---
    // On CSRRW (opcode 1110011, funct3==001), write value of rs1 into CSR.
    // If CSR addr is 0xF02 or 0xF03 -> map to gpio_out (direct 32-bit).
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) gpio_out <= 32'd0;
        else begin
            if (opcode_EX == 7'b1110011 && funct3_EX == 3'b001) begin
                if (csr_addr_EX == 12'hF02 || csr_addr_EX == 12'hF03) begin
                    // write value of rs1 (we have rf_readdata1_EX available in EX stage)
                    gpio_out <= rf_readdata1_EX;
                end
            end
        end
    end

endmodule

