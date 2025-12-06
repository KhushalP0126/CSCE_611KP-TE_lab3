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
    // 64-bit wide instruction memory (4096 32-bit words -> 2048 entries)
    (* ramstyle = "M9K", keep = 1 *) logic [63:0] instmem [0:2048];
    initial $readmemh("instmem.dat", instmem);

    // Program counter (word addressed)
    (* keep = 1 *) logic [11:0] pc_F;
    logic [11:0] pc0_EX;
    logic [11:0] pc1_EX;
    logic [11:0] pc_next;
    (* keep = 1 *) logic [31:0] instr0_EX;
    (* keep = 1 *) logic [31:0] instr1_EX;
    (* keep = 1 *) logic        slot0_valid_EX;
    (* keep = 1 *) logic        slot1_valid_EX;
    (* keep = 1 *) logic        flush_EX;

    // Fetch two instructions per cycle (pairing from 64-bit words)
    logic [63:0] instline0;
    logic [63:0] instline1;
    (* keep = 1 *) logic [31:0] instr0_F;
    (* keep = 1 *) logic [31:0] instr1_F;
    (* keep = 1 *) logic        slot1_issue_F;
    logic        slot1_available_F;
    logic [6:0]  opcode0_F;
    logic [6:0]  opcode1_F;
    logic [4:0]  rd0_F, rd1_F;
    logic [4:0]  rs1_0_F, rs2_0_F;
    logic [4:0]  rs1_1_F, rs2_1_F;
    logic        slot0_ctrlflow_F;
    logic        slot1_ctrlflow_F;
    logic        slot0_writes_rd_F;
    logic        slot1_uses_rs2_F;
    logic        slot1_depblock_F;

    logic [11:0] issue_count_F;

    assign instline0 = instmem[pc_F[11:1]];
    assign instline1 = instmem[pc_F[11:1] + 12'd1];
    assign instr0_F  = pc_F[0] ? instline0[63:32] : instline0[31:0];
    assign instr1_F  = pc_F[0] ? instline1[31:0]  : instline0[63:32];
    assign slot1_available_F = (pc_F != 12'd4095);

    assign opcode0_F = instr0_F[6:0];
    assign opcode1_F = instr1_F[6:0];
    assign rd0_F     = instr0_F[11:7];
    assign rd1_F     = instr1_F[11:7];
    assign rs1_0_F   = instr0_F[19:15];
    assign rs2_0_F   = instr0_F[24:20];
    assign rs1_1_F   = instr1_F[19:15];
    assign rs2_1_F   = instr1_F[24:20];

    assign slot0_ctrlflow_F = (opcode0_F == 7'b1100011) // branch
                            || (opcode0_F == 7'b1101111) // JAL
                            || (opcode0_F == 7'b1100111); // JALR
    assign slot1_ctrlflow_F = (opcode1_F == 7'b1100011)
                            || (opcode1_F == 7'b1101111)
                            || (opcode1_F == 7'b1100111);
    assign slot0_writes_rd_F = (opcode0_F == 7'b0110011)   // R-type
                             || (opcode0_F == 7'b0010011)  // I-type arithmetic
                             || (opcode0_F == 7'b0110111)  // LUI
                             || (opcode0_F == 7'b1101111)  // JAL
                             || (opcode0_F == 7'b1100111)  // JALR
                             || (opcode0_F == 7'b1110011); // CSRRW
    assign slot1_uses_rs2_F = (opcode1_F == 7'b0110011);
    assign slot1_depblock_F = slot0_writes_rd_F && (rd0_F != 5'd0)
                            && ((rd0_F == rs1_1_F)
                               || (slot1_uses_rs2_F && (rd0_F == rs2_1_F)));

    assign slot1_issue_F = slot1_available_F
                         && ~slot0_ctrlflow_F
                         && ~slot1_ctrlflow_F
                         && ~slot1_depblock_F;

    assign issue_count_F = slot1_issue_F ? 12'd2 : 12'd1;

    // active-low asynchronous reset: sensitive to negedge rst
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            pc_F          <= 12'd0;
            pc0_EX        <= 12'd0;
            pc1_EX        <= 12'd0;
            instr0_EX     <= 32'd0;
            instr1_EX     <= 32'd0;
            slot0_valid_EX <= 1'b0;
            slot1_valid_EX <= 1'b0;
        end else begin
            pc_F   <= pc_next;
            pc0_EX <= pc_F;
            pc1_EX <= pc_F + 12'd1;
            if (flush_EX) begin
                instr0_EX      <= 32'd0;
                instr1_EX      <= 32'd0;
                slot0_valid_EX <= 1'b0;
                slot1_valid_EX <= 1'b0;
            end else begin
                instr0_EX      <= instr0_F;
                instr1_EX      <= instr1_F;
                slot0_valid_EX <= 1'b1;
                slot1_valid_EX <= slot1_issue_F;
            end
        end
    end

    // ---- decoder outputs in EX stage (slot 0 + slot 1) ----
    logic [6:0]  opcode0_EX, opcode1_EX;
    logic [6:0]  funct7_0_EX, funct7_1_EX;
    logic [2:0]  funct3_0_EX, funct3_1_EX;
    logic [4:0]  rd0_EX, rd1_EX;
    logic [4:0]  rs1_0_EX, rs2_0_EX;
    logic [4:0]  rs1_1_EX, rs2_1_EX;
    logic [31:0] imm_i_0_EX, imm_i_1_EX;
    logic [31:0] imm_u_0_EX, imm_u_1_EX;
    logic [31:0] imm_b_0_EX, imm_b_1_EX;
    logic [31:0] imm_j_0_EX, imm_j_1_EX;
    logic [4:0]  shamt0_EX, shamt1_EX;
    logic [1:0]  instr_type0_EX, instr_type1_EX;

    instruction_decoder id0 (
        .instr(instr0_EX),
        .opcode(opcode0_EX),
        .funct7(funct7_0_EX),
        .funct3(funct3_0_EX),
        .rd(rd0_EX),
        .rs1(rs1_0_EX),
        .rs2(rs2_0_EX),
        .imm_i(imm_i_0_EX),
        .imm_u(imm_u_0_EX),
        .imm_b(imm_b_0_EX),
        .imm_j(imm_j_0_EX),
        .shamt(shamt0_EX),
        .instr_type(instr_type0_EX)
    );

    instruction_decoder id1 (
        .instr(instr1_EX),
        .opcode(opcode1_EX),
        .funct7(funct7_1_EX),
        .funct3(funct3_1_EX),
        .rd(rd1_EX),
        .rs1(rs1_1_EX),
        .rs2(rs2_1_EX),
        .imm_i(imm_i_1_EX),
        .imm_u(imm_u_1_EX),
        .imm_b(imm_b_1_EX),
        .imm_j(imm_j_1_EX),
        .shamt(shamt1_EX),
        .instr_type(instr_type1_EX)
    );

    // ---- control signals in EX stage ----
    logic        alusrc0_EX, alusrc1_EX;
    logic        regwrite0_EX, regwrite1_EX;
    logic [1:0]  regsel0_EX, regsel1_EX;
    logic [3:0]  aluop0_EX, aluop1_EX;
    logic [11:0] csr_addr0_EX, csr_addr1_EX;
    logic        gpio_we0_EX, gpio_we1_EX;
    logic        csr_en0_EX, csr_en1_EX;
    logic        branch0_EX, branch1_EX;
    logic        jal0_EX, jal1_EX;
    logic        jalr0_EX, jalr1_EX;

    control_unit cu0 (
        .opcode(opcode0_EX),
        .funct3(funct3_0_EX),
        .funct7(funct7_0_EX),
        .instr_type(instr_type0_EX),
        .csr_imm(instr0_EX[31:20]),

        .alusrc(alusrc0_EX),
        .gpio_we(gpio_we0_EX),
        .regwrite(regwrite0_EX),
        .regsel(regsel0_EX),
        .aluop(aluop0_EX),
        .csr_addr(csr_addr0_EX),
        .branch(branch0_EX),
        .jal(jal0_EX),
        .jalr(jalr0_EX),
        .csr_en(csr_en0_EX)
    );

    control_unit cu1 (
        .opcode(opcode1_EX),
        .funct3(funct3_1_EX),
        .funct7(funct7_1_EX),
        .instr_type(instr_type1_EX),
        .csr_imm(instr1_EX[31:20]),

        .alusrc(alusrc1_EX),
        .gpio_we(gpio_we1_EX),
        .regwrite(regwrite1_EX),
        .regsel(regsel1_EX),
        .aluop(aluop1_EX),
        .csr_addr(csr_addr1_EX),
        .branch(branch1_EX),
        .jal(jal1_EX),
        .jalr(jalr1_EX),
        .csr_en(csr_en1_EX)
    );

    // ---- register file (external) ----
    logic [31:0] rf_readdata1_0_EX, rf_readdata2_0_EX;
    logic [31:0] rf_readdata1_1_EX, rf_readdata2_1_EX;
    logic [31:0] rf_writedata0_WB, rf_writedata1_WB;
    logic [31:0] alu_result0_WB, alu_result1_WB;
    logic [31:0] csr_read0_WB, csr_read1_WB;
    logic [4:0]  rd0_WB, rd1_WB;
    logic [1:0]  regsel0_WB, regsel1_WB;
    logic        regwrite0_WB, regwrite1_WB;
    logic [31:0] imm_u0_WB, imm_u1_WB;
    logic [11:0] csr_addr0_WB, csr_addr1_WB;
    logic [31:0] rs1_value0_WB, rs1_value1_WB;
    logic        gpio_we0_WB, gpio_we1_WB;
    logic [31:0] pc_plus4_0_WB, pc_plus4_1_WB;

    regfile rf (
        .clk        (clk),
        .we         (regwrite0_WB),
        .we2        (regwrite1_WB),
        .readaddr1  (rs1_0_EX),
        .readaddr2  (rs2_0_EX),
        .readaddr3  (rs1_1_EX),
        .readaddr4  (rs2_1_EX),
        .writeaddr  (rd0_WB),
        .writeaddr2 (rd1_WB),
        .writedata  (rf_writedata0_WB),
        .writedata2 (rf_writedata1_WB),
        .readdata1  (rf_readdata1_0_EX),
        .readdata2  (rf_readdata2_0_EX),
        .readdata3  (rf_readdata1_1_EX),
        .readdata4  (rf_readdata2_1_EX)
    );

    // Forward register file outputs from previous WB stage results (slot-order aware)
    function automatic logic [31:0] forward_value (
        input logic [31:0] raw_value,
        input logic [4:0]  rs_addr
    );
        logic [31:0] value;
        begin
            value = raw_value;
            if (regwrite0_WB && (rd0_WB != 5'd0) && (rd0_WB == rs_addr)) begin
                value = rf_writedata0_WB;
            end
            if (regwrite1_WB && (rd1_WB != 5'd0) && (rd1_WB == rs_addr)) begin
                value = rf_writedata1_WB;
            end
            forward_value = value;
        end
    endfunction

    logic [31:0] rs1_dat0;
    logic [31:0] rs2_dat0;
    logic [31:0] rs1_dat1;
    logic [31:0] rs2_dat1;

    assign rs1_dat0 = forward_value(rf_readdata1_0_EX, rs1_0_EX);
    assign rs2_dat0 = forward_value(rf_readdata2_0_EX, rs2_0_EX);
    assign rs1_dat1 = forward_value(rf_readdata1_1_EX, rs1_1_EX);
    assign rs2_dat1 = forward_value(rf_readdata2_1_EX, rs2_1_EX);

    // ---- ALU inputs selection ----
    logic [31:0] alu_A0_EX, alu_B0_EX;
    logic [31:0] alu_A1_EX, alu_B1_EX;
    logic [31:0] imm_shamt0_EX, imm_shamt1_EX;

    assign alu_A0_EX = rs1_dat0;
    assign alu_A1_EX = rs1_dat1;

    // if shift-immediate, use shamt; else use imm_i
    assign imm_shamt0_EX = ((instr_type0_EX == 2'b01) && (funct3_0_EX == 3'b001 || funct3_0_EX == 3'b101))
                           ? {{27{1'b0}}, shamt0_EX}
                           : imm_i_0_EX;
    assign imm_shamt1_EX = ((instr_type1_EX == 2'b01) && (funct3_1_EX == 3'b001 || funct3_1_EX == 3'b101))
                           ? {{27{1'b0}}, shamt1_EX}
                           : imm_i_1_EX;

    assign alu_B0_EX = (alusrc0_EX) ? imm_shamt0_EX : rs2_dat0;
    assign alu_B1_EX = (alusrc1_EX) ? imm_shamt1_EX : rs2_dat1;

    // ALUs (slot 0 and slot 1)
    logic [31:0] alu_R0_EX, alu_R1_EX;
    logic        alu_zero0_EX, alu_zero1_EX;

    alu alu0 (
        .A (alu_A0_EX),
        .B (alu_B0_EX),
        .op(aluop0_EX),
        .R (alu_R0_EX),
        .zero(alu_zero0_EX)
    );

    alu alu1 (
        .A (alu_A1_EX),
        .B (alu_B1_EX),
        .op(aluop1_EX),
        .R (alu_R1_EX),
        .zero(alu_zero1_EX)
    );

    // ---- Branch / jump calculations (slot 0 drives control flow) ----
    logic        branch_taken0_EX;
    logic [11:0] branch_target_word;
    logic [11:0] jal_target_word;
    logic [11:0] jalr_target_word;
    logic [31:0] pc_plus4_0_EX;
    logic [31:0] pc_plus4_1_EX;

    logic signed [31:0] pc0_ex_bytes;
    logic signed [31:0] branch_target_bytes;
    logic signed [31:0] jal_target_bytes;
    logic signed [31:0] jalr_target_bytes;
    logic signed [31:0] branch_target_word32;
    logic signed [31:0] jal_target_word32;
    logic signed [31:0] jalr_target_word32;

    assign pc0_ex_bytes         = $signed({{20{1'b0}}, pc0_EX, 2'b00});
    assign branch_target_bytes  = pc0_ex_bytes + $signed(imm_b_0_EX);
    assign jal_target_bytes     = pc0_ex_bytes + $signed(imm_j_0_EX);
    assign jalr_target_bytes    = $signed((rs1_dat0 + imm_i_0_EX) & ~32'd1);

    assign branch_target_word32 = branch_target_bytes >>> 2;
    assign jal_target_word32    = jal_target_bytes >>> 2;
    assign jalr_target_word32   = jalr_target_bytes >>> 2;

    assign branch_target_word   = branch_target_word32[11:0];
    assign jal_target_word      = jal_target_word32[11:0];
    assign jalr_target_word     = jalr_target_word32[11:0];
    assign pc_plus4_0_EX        = {{20{1'b0}}, pc0_EX, 2'b00} + 32'd4;
    assign pc_plus4_1_EX        = {{20{1'b0}}, pc1_EX, 2'b00} + 32'd4;

    always_comb begin
        branch_taken0_EX = 1'b0;
        if (slot0_valid_EX && branch0_EX) begin
            unique case (funct3_0_EX)
                3'b000: branch_taken0_EX = (rs1_dat0 == rs2_dat0);                       // BEQ
                3'b001: branch_taken0_EX = (rs1_dat0 != rs2_dat0);                       // BNE
                3'b100: branch_taken0_EX = ($signed(rs1_dat0) <  $signed(rs2_dat0));     // BLT
                3'b101: branch_taken0_EX = ($signed(rs1_dat0) >= $signed(rs2_dat0));     // BGE
                3'b110: branch_taken0_EX = (rs1_dat0 < rs2_dat0);                        // BLTU
                3'b111: branch_taken0_EX = (rs1_dat0 >= rs2_dat0);                       // BGEU
                default: branch_taken0_EX = 1'b0;
            endcase
        end
    end

    assign flush_EX = slot0_valid_EX && (branch_taken0_EX | jal0_EX | jalr0_EX);

    always_comb begin
        if (slot0_valid_EX && jalr0_EX) begin
            pc_next = jalr_target_word;
        end else if (slot0_valid_EX && jal0_EX) begin
            pc_next = jal_target_word;
        end else if (slot0_valid_EX && branch_taken0_EX) begin
            pc_next = branch_target_word;
        end else begin
            pc_next = pc_F + issue_count_F;
        end
    end

    // ---- EX -> WB registers ----

    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            alu_result0_WB <= 32'd0;
            alu_result1_WB <= 32'd0;
            csr_read0_WB   <= 32'd0;
            csr_read1_WB   <= 32'd0;
            rd0_WB         <= 5'd0;
            rd1_WB         <= 5'd0;
            regsel0_WB     <= 2'b00;
            regsel1_WB     <= 2'b00;
            regwrite0_WB   <= 1'b0;
            regwrite1_WB   <= 1'b0;
            imm_u0_WB      <= 32'd0;
            imm_u1_WB      <= 32'd0;
            gpio_we0_WB    <= 1'b0;
            gpio_we1_WB    <= 1'b0;
            csr_addr0_WB   <= 12'd0;
            csr_addr1_WB   <= 12'd0;
            rs1_value0_WB  <= 32'd0;
            rs1_value1_WB  <= 32'd0;
            pc_plus4_0_WB  <= 32'd0;
            pc_plus4_1_WB  <= 32'd0;
        end else begin
            alu_result0_WB <= alu_R0_EX;
            alu_result1_WB <= alu_R1_EX;

            csr_addr0_WB <= csr_addr0_EX;
            csr_addr1_WB <= csr_addr1_EX;

            if (slot0_valid_EX && csr_en0_EX) begin
                case (csr_addr0_EX)
                    12'hF00: csr_read0_WB <= gpio_in;
                    12'hF02: csr_read0_WB <= gpio_out;
                    default: csr_read0_WB <= 32'd0;
                endcase
            end else begin
                csr_read0_WB <= 32'd0;
            end

            if (slot1_valid_EX && csr_en1_EX) begin
                if (slot0_valid_EX && csr_en0_EX && (csr_addr0_EX == csr_addr1_EX)) begin
                    // slot 0 writes CSR before slot 1 reads it -> bypass new value
                    csr_read1_WB <= rs1_dat0;
                end else begin
                    case (csr_addr1_EX)
                        12'hF00: csr_read1_WB <= gpio_in;
                        12'hF02: csr_read1_WB <= gpio_out;
                        default: csr_read1_WB <= 32'd0;
                    endcase
                end
            end else begin
                csr_read1_WB <= 32'd0;
            end

            rd0_WB       <= rd0_EX;
            rd1_WB       <= rd1_EX;
            regsel0_WB   <= regsel0_EX;
            regsel1_WB   <= regsel1_EX;
            regwrite0_WB <= slot0_valid_EX ? regwrite0_EX : 1'b0;
            regwrite1_WB <= slot1_valid_EX ? regwrite1_EX : 1'b0;
            imm_u0_WB    <= imm_u_0_EX;
            imm_u1_WB    <= imm_u_1_EX;
            gpio_we0_WB  <= slot0_valid_EX ? gpio_we0_EX : 1'b0;
            gpio_we1_WB  <= slot1_valid_EX ? gpio_we1_EX : 1'b0;
            rs1_value0_WB <= rs1_dat0;
            rs1_value1_WB <= rs1_dat1;
            pc_plus4_0_WB <= pc_plus4_0_EX;
            pc_plus4_1_WB <= pc_plus4_1_EX;
        end
    end

    // ---- Writeback selection ----
    always_comb begin
        unique case (regsel0_WB)
            2'b00: rf_writedata0_WB = alu_result0_WB;
            2'b01: rf_writedata0_WB = csr_read0_WB;
            2'b10: rf_writedata0_WB = imm_u0_WB;
            2'b11: rf_writedata0_WB = pc_plus4_0_WB;
            default: rf_writedata0_WB = alu_result0_WB;
        endcase

        unique case (regsel1_WB)
            2'b00: rf_writedata1_WB = alu_result1_WB;
            2'b01: rf_writedata1_WB = csr_read1_WB;
            2'b10: rf_writedata1_WB = imm_u1_WB;
            2'b11: rf_writedata1_WB = pc_plus4_1_WB;
            default: rf_writedata1_WB = alu_result1_WB;
        endcase
    end

    // ---- CSR / GPIO writes (handle writes to io2 -> gpio_out) ---
    // On CSRRW (opcode 1110011, funct3==001), write value of rs1 into CSR.
    // If CSR addr is 0xF02 -> map to gpio_out (direct 32-bit). Later slot wins.
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            gpio_out <= 32'd0;
        end else begin
            if (gpio_we0_WB && (csr_addr0_WB == 12'hF02)) begin
                gpio_out <= rs1_value0_WB;
            end
            if (gpio_we1_WB && (csr_addr1_WB == 12'hF02)) begin
                gpio_out <= rs1_value1_WB;
            end
        end
    end

endmodule
