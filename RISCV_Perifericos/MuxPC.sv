//========================================================
// Module  : MuxPC
// Función : Selecciona próximo PC (pc+4 o branch/jump target)
//========================================================

//========================================================
// Módulo : MuxPC
// Descripción: Selecciona el próximo PC entre pc+4, branch/jal y jalr
//========================================================
`default_nettype none

module MuxPC (
    input  logic [1:0]  PCsrc,          // 00=pc+4, 01=branch/jal, 10=jalr
    input  logic [31:0] pc_plus4,       
    input  logic [31:0] branch_target,  // pc + ImmExt
    input  logic [31:0] jal_target,     // rs1 + ImmExt
    output logic [31:0] pc_next
);

    logic [31:0] jalr_aligned;
    assign jalr_aligned = {jal_target[31:1], 1'b0}; 

    always_comb begin
        case (PCsrc)
            2'b00: pc_next = pc_plus4;
            2'b01: pc_next = branch_target;
            2'b10: pc_next = jalr_aligned;
            default: pc_next = pc_plus4;
        endcase
    end

endmodule

`default_nettype wire
