//=============================================================
// Module  : Instruction_parser
// Descripcion: Este módulo se encarga de decodificar los campos
//              básicos de una instrucción RISC-V de 32 bits.
//              A partir de la instrucción (Inst) extrae:
//==============================================================

module Instruction_parser(

    input  logic [31:0] Inst,
    output logic [2:0]  Funct3,
    output logic [4:0]  raddr1,raddr2,waddr,
    output logic [6:0]  opcode,
    output logic [6:0]  Funct7
);

    assign opcode = Inst[6:0];
    assign waddr  = Inst[11:7];
    assign Funct3 = Inst[14:12];
    assign raddr1 = Inst[19:15];
    assign raddr2 = Inst[24:20];
    assign Funct7 = Inst[31:25];
 
endmodule