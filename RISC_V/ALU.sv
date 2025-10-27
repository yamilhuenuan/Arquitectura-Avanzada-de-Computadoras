// ========================================================
// Module  : ALU
// ========================================================

module ALU (
    input  logic [3:0]  alu_op,      
    input  logic [31:0] SrcA, SrcB,
    output logic [31:0] alu_result    
);

    localparam [3:0]
        ALU_ADD  = 4'b0000,
        ALU_SUB  = 4'b0001,
        ALU_SLL  = 4'b0010,
        ALU_SLT  = 4'b0011,
        ALU_SLTU = 4'b0100,
        ALU_XOR  = 4'b0101,
        ALU_SRL  = 4'b0110,
        ALU_SRA  = 4'b0111,
        ALU_OR   = 4'b1000,
        ALU_AND  = 4'b1001,
        ALU_LUI  = 4'b1010;

    always_comb begin
        case (alu_op)
            ALU_ADD:  alu_result = SrcA + SrcB;
            ALU_SUB:  alu_result = SrcA - SrcB;
            ALU_SLL:  alu_result = SrcA << SrcB[4:0];
            ALU_SLT:  alu_result = ($signed(SrcA) < $signed(SrcB)) ? 32'd1 : 32'd0;
            ALU_SLTU: alu_result = (SrcA < SrcB) ? 32'd1 : 32'd0;
            ALU_XOR:  alu_result = SrcA ^ SrcB;
            ALU_SRL:  alu_result = SrcA >> SrcB[4:0];
            ALU_SRA:  alu_result = $signed(SrcA) >>> SrcB[4:0];
            ALU_OR:   alu_result = SrcA | SrcB;
            ALU_AND:  alu_result = SrcA & SrcB;
            ALU_LUI:  alu_result = SrcB;
            default:  alu_result = 32'd0; 
        endcase
    end

endmodule