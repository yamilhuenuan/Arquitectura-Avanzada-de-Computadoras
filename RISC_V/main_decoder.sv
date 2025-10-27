//========================================================
// Módulo  : control_unit
// Descripción: Unidad de control principal para RV32I.
//              Decodifica opcode y funct3 para generar
//              todas las señales de control del datapath.
//========================================================
`default_nettype none

module main_decoder (
    input  logic [6:0] opcode,   // Inst[6:0]
    input  logic [2:0] funct3,   // Inst[14:12]

    output logic       RegWrite,
    output logic       ALUSrcA,
    output logic       ALUSrcB,
    output logic       MemWrite,
    output logic       MemRead,
    output logic       Branch,
    output logic       Jump,
    output logic [1:0] MemToReg, // 00=PC+4, 01=ALU, 10=Mem
    output logic [2:0] ImmSrc,   // 000=I, 001=S, 010=B, 011=J, 100=U
    output logic [1:0] ALUOp,    // 00=ADD, 01=BR, 10=ALU, 11=LUI
    output logic [1:0] MemSize,  // 00=byte, 01=half, 10=word
    output logic       MemSign   // 1=signed, 0=unsigned
);

    always_comb begin
        // Valores por defecto
        RegWrite = 0; ALUSrcA = 0; ALUSrcB = 0;
        MemWrite = 0; MemRead = 0;
        Branch   = 0; Jump = 0;
        MemToReg = 2'b01; // por defecto ALU
        ImmSrc   = 3'b000;
        ALUOp    = 2'b00;
        MemSize  = 2'b10; // word
        MemSign  = 1;     // signed

        case (opcode)

            // ---------------- R-type ----------------
            7'b0110011: begin
                RegWrite = 1;
                ALUSrcA  = 1;   // rs1
                ALUSrcB  = 0;   // rs2
                MemToReg = 2'b01;
                ALUOp    = 2'b10; // usar funct3/funct7
            end

            // ---------------- I-type ALU ----------------
            7'b0010011: begin
                RegWrite = 1;
                ALUSrcA  = 1;
                ALUSrcB  = 1;   // imm
                MemToReg = 2'b01;
                ImmSrc   = 3'b000; // I-type
                ALUOp    = 2'b10;
            end

            // ---------------- Load ----------------
            7'b0000011: begin
                RegWrite = 1;
                ALUSrcA  = 1;
                ALUSrcB  = 1;
                MemRead  = 1;
                MemToReg = 2'b10; // Mem
                ImmSrc   = 3'b000;
                ALUOp    = 2'b00; // ADD
                case (funct3)
                    3'b000: begin MemSize=2'b00; MemSign=1; end // LB
                    3'b001: begin MemSize=2'b01; MemSign=1; end // LH
                    3'b010: begin MemSize=2'b10; MemSign=1; end // LW
                    3'b100: begin MemSize=2'b00; MemSign=0; end // LBU
                    3'b101: begin MemSize=2'b01; MemSign=0; end // LHU
                endcase
            end

            // ---------------- Store ----------------
            7'b0100011: begin
                ALUSrcA  = 1;
                ALUSrcB  = 1;
                MemWrite = 1;
                ImmSrc   = 3'b001; // S-type
                ALUOp    = 2'b00;  // ADD
                case (funct3)
                    3'b000: MemSize=2'b00; // SB
                    3'b001: MemSize=2'b01; // SH
                    3'b010: MemSize=2'b10; // SW
                endcase
            end

            // ---------------- LUI ----------------
            7'b0110111: begin
                RegWrite = 1;
                ALUSrcB  = 1;
                MemToReg = 2'b01;
                ImmSrc   = 3'b100; // U-type
                ALUOp    = 2'b11;  // LUI
            end

            // ---------------- AUIPC ----------------
            7'b0010111: begin
                RegWrite = 1;
                ALUSrcA  = 0; // PC
                ALUSrcB  = 1; // Imm
                MemToReg = 2'b01;
                ImmSrc   = 3'b100;
                ALUOp    = 2'b00; // ADD
            end

            // ---------------- Branch ----------------
            7'b1100011: begin
                ALUSrcA  = 0; // PC for branch target
                ALUSrcB  = 1;
                Branch   = 1;
                ImmSrc   = 3'b010; // B-type
                ALUOp    = 2'b01;  // comparar en branch_unit
            end

            // ---------------- JAL ----------------
            7'b1101111: begin
                RegWrite = 1;
                Jump     = 1;
                ALUSrcA  = 0; // PC
                ALUSrcB  = 1;
                MemToReg = 2'b00; // PC+4
                ImmSrc   = 3'b011; // J-type
                ALUOp    = 2'b00;  // ADD
            end

            // ---------------- JALR ----------------
            7'b1100111: begin
                RegWrite = 1;
                Jump     = 1;
                ALUSrcA  = 1; // rs1
                ALUSrcB  = 1; // imm
                MemToReg = 2'b00; // PC+4
                ImmSrc   = 3'b000; // I-type
                ALUOp    = 2'b00;  // ADD
            end

            default: ; // NOP para SYSTEM/CSR, FENCE, etc.
        endcase
    end

endmodule

`default_nettype wire