//========================================================
// Module  : PCplus4
//========================================================

module PCplus4(
    
    input [31:0] pc_in,
    output [31:0] pc_plus4
);

    assign pc_plus4 = pc_in + 4 ;
    
endmodule