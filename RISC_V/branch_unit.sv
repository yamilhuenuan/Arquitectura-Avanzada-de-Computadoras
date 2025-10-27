//========================================================
// Módulo  : branch_unit
// Descripción: Evalúa la condición de branch (RV32I).
//========================================================

module branch_unit (
    input  logic [2:0]  funct3,     
    input  logic [31:0] rs1,        
    input  logic [31:0] rs2,        
    output logic        br_flag    
);

    always_comb begin
        case (funct3)
            3'b000: br_flag = (rs1 == rs2);                         // BEQ
            3'b001: br_flag = (rs1 != rs2);                         // BNE
            3'b100: br_flag = ($signed(rs1) <  $signed(rs2));       // BLT
            3'b101: br_flag = ($signed(rs1) >= $signed(rs2));       // BGE
            3'b110: br_flag = (rs1 < rs2);                          // BLTU
            3'b111: br_flag = (rs1 >= rs2);                         // BGEU
            default: br_flag = 1'b0;                                // no branch
        endcase
    end

endmodule