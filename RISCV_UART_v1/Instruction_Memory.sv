//========================================================
// Module  : Instruction_Memory
// Función : Memoria de instrucciones (ROM) para RV32I
//========================================================

module Instruction_Memory (
    input  logic [31:0] addr,       
    output logic [31:0] inst        
);

    logic [31:0] instr_mem [0:1023]; 

    initial begin
    
        $readmemh("program.hex", instr_mem);
        
    end

    assign inst = instr_mem[addr[11:2]];  

endmodule
