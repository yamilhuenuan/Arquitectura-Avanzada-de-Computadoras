//========================================================
// Módulo  : mux_writeback
// Descripción: Multiplexor de la etapa Write Back.
//              Selecciona entre PC+4, ALUResult o MemData.
//========================================================
`default_nettype none

module mux_writeback (
    input  logic [31:0] PCplus4,     // PC + 4 (para JAL/JALR)
    input  logic [31:0] ALUResult,   // resultado de la ALU
    input  logic [31:0] MemData,     // dato leído de memoria
    input  logic [1:0]  MemToReg,    // selector
    output logic [31:0] WriteData    // dato seleccionado
);

    always_comb begin
        case (MemToReg)
            2'b00: WriteData = PCplus4;
            2'b01: WriteData = ALUResult;
            2'b10: WriteData = MemData;
            default: WriteData = 32'hXXXXXXXX;
        endcase
    end

endmodule

`default_nettype wire