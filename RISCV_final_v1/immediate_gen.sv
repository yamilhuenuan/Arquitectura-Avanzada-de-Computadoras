module immediate_gen (
  input  logic [31:0] Inst,     
  input  logic [2:0]  ImmSrcD,  
  output logic [31:0] ImmExtD   
);

  // Definir todas las posibles extensiones
  logic [31:0] imm_i, imm_s, imm_b, imm_j, imm_u;
  
  assign imm_i = {{20{Inst[31]}}, Inst[31:20]};
  assign imm_s = {{20{Inst[31]}}, Inst[31:25], Inst[11:7]};
  assign imm_b = {{19{Inst[31]}}, Inst[31], Inst[7], Inst[30:25], Inst[11:8], 1'b0};
  assign imm_j = {{11{Inst[31]}}, Inst[31], Inst[19:12], Inst[20], Inst[30:21], 1'b0};
  assign imm_u = {Inst[31:12], 12'b0};

  always_comb begin
    case (ImmSrcD)
      3'b000: ImmExtD = imm_i;  // I-type
      3'b001: ImmExtD = imm_s;  // S-type
      3'b010: ImmExtD = imm_b;  // B-type
      3'b011: ImmExtD = imm_j;  // J-type
      3'b100: ImmExtD = imm_u;  // U-type
      default: ImmExtD = 32'hXXXXXXXX;
    endcase
  end

endmodule