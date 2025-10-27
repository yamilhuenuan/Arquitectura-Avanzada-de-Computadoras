//=============================================================
// Módulo : mux_selA
// Descripción: Multiplexor para la entrada A de la ALU.
//              Selecciona entre:
//                                  - PC/Addr (cuando sel_A=0)
//                                  - rdata1  (cuando sel_A=1)
//=============================================================

module mux_selA (
    input logic         sel_A,
    input logic  [31:0] rdata1,Addr,
    output logic [31:0] SrcA
);

always_comb begin 
    case (sel_A)
       1'b0 : SrcA = Addr;
       1'b1 : SrcA = rdata1;
    endcase  
end
endmodule