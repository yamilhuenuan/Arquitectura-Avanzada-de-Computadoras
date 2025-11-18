//==============================================================
// Módulo  : mux_selB
// Descripción: Multiplexor para la entrada B de la ALU.
//              Selecciona entre:
//                                  - rdata2   (cuando sel_B=0)
//                                  - ImmExtD  (cuando sel_B=1)
//==============================================================

module mux_selB (
    input logic         sel_B, 
    input logic  [31:0] ImmExtD,rdata2,
    output logic [31:0] SrcB
);

always_comb begin 
    case (sel_B)
       1'b0 : SrcB = rdata2;
       1'b1 : SrcB = ImmExtD;
    endcase
    
end
    
endmodule