// instruction_decoder.sv
// Extract fields from a 32-bit RISC-V instruction and produce immediates/shamt.
// Simple classification: 00=R,01=I,10=U,11=OTHER

module instruction_decoder (
    input  logic [31:0] instr,

    // raw fields
    output logic [6:0]  opcode,
    output logic [6:0]  funct7,
    output logic [2:0]  funct3,
    output logic [4:0]  rd,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,

    // immediates / shamt
    output logic [31:0] imm_i,    // sign-extended I-type imm
    output logic [31:0] imm_u,    // U-type imm << 12
    output logic [4:0]  shamt,

    // instruction class hint
    output logic [1:0]  instr_type // 00=R,01=I,10=U,11=OTHER
);

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // I-type immediate (sign-extend imm[11:0])
    logic [11:0] imm12;
    assign imm12 = instr[31:20];
    assign imm_i = {{20{imm12[11]}}, imm12};

    // U-type immediate (imm[31:12] << 12)
    logic [19:0] imm20;
    assign imm20 = instr[31:12];
    assign imm_u = {imm20, 12'b0};

    // shamt for shift-immediate encoded in instr[24:20]
    assign shamt = instr[24:20];

    // simple opcode-based classification
    always_comb begin
        unique case (opcode)
            7'b0110011: instr_type = 2'b00; // R-type
            7'b0010011: instr_type = 2'b01; // I-type (arith imm / shifts)
            7'b0110111: instr_type = 2'b10; // U-type (LUI)
            7'b1110011: instr_type = 2'b01; // CSR family encoded as I-type (csrrw)
            default:     instr_type = 2'b11;
        endcase
    end

endmodule

