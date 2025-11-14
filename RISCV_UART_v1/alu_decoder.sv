//========================================================
// Módulo  : alu_control
// Descripción: Decodifica ALUOp + funct3/funct7 para
//              seleccionar la operación específica de la ALU.
//========================================================

module alu_decoder (
    input  logic [1:0] ALUOp,      // Señal desde main_decoder
    input  logic [2:0] funct3,     // Inst[14:12]
    input  logic [6:0] funct7,     // Inst[31:25]
    output logic [3:0] alu_op      // Código para ALU
);

    // Definiciones de operaciones
    parameter [3:0] ADD  = 4'b0000;
    parameter [3:0] SUB  = 4'b0001;
    parameter [3:0] SLL  = 4'b0010;
    parameter [3:0] SLT  = 4'b0011;
    parameter [3:0] SLTU = 4'b0100;
    parameter [3:0] XOR  = 4'b0101;
    parameter [3:0] SRL  = 4'b0110;
    parameter [3:0] SRA  = 4'b0111;
    parameter [3:0] OR   = 4'b1000;
    parameter [3:0] AND  = 4'b1001;
    parameter [3:0] LUI  = 4'b1010;

    always_comb begin
        case (ALUOp)
            // 00 -> operación básica (suma, ej: load/store, addi, jal, jalr)
            2'b00: alu_op = ADD;

            // 01 -> branches (solo comparaciones con suma/resta)
            2'b01: alu_op = SUB;   // BEQ, BNE, BLT, BGE, etc. usan restas

            // 10 -> operaciones ALU de R-type / I-type
            2'b10: begin
                case (funct3)
                    3'b000: alu_op = (funct7 == 7'b0100000) ? SUB : ADD; // ADD/SUB
                    3'b001: alu_op = SLL;   // Shift Left Logical
                    3'b010: alu_op = SLT;   // Set Less Than (signed)
                    3'b011: alu_op = SLTU;  // Set Less Than (unsigned)
                    3'b100: alu_op = XOR;
                    3'b101: alu_op = (funct7 == 7'b0100000) ? SRA : SRL; // Shift Right
                    3'b110: alu_op = OR;
                    3'b111: alu_op = AND;
                    default: alu_op = ADD;
                endcase
            end

            // 11 -> instrucciones especiales (ej: LUI)
            2'b11: alu_op = LUI;

            default: alu_op = ADD;
        endcase
    end

endmodule
