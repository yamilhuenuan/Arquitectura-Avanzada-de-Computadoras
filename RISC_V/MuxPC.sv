//========================================================
// Module  : MuxPC
// Función : Selecciona próximo PC (pc+4 o branch/jump target)
//========================================================

module MuxPC (
    input  logic        PCsrc,         // Señal de control (0=secuencial, 1=branch/jump)
    input  logic [31:0] pc_plus4,      // PC + 4
    input  logic [31:0] branch_target, // Dirección de salto
    output logic [31:0] pc_next        // Próximo PC
);

    assign pc_next = (PCsrc) ? branch_target : pc_plus4;

endmodule