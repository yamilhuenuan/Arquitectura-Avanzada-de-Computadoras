//========================================================
// Top module: Instruction Fetch stage (RV32I con branch/jump)
//========================================================

module Fetch_Module (
    input  logic        clk,
    input  logic        rst,
    input  logic        PCsrc,          // Señal de control: 0=pc+4, 1=branch/jump
    input  logic [31:0] branch_target,  // Dirección de salto calculada en EX
    output logic [31:0] pc_current,     // PC actual
    output logic [31:0] inst            // Instrucción actual
);

    logic [31:0] pc_in;
    logic [31:0] pc_out;
    logic [31:0] pc_plus4;

    program_counter PC_reg (.clk(clk),.rst(rst),.pc_in(pc_in),.pc_out (pc_out));
    PCplus4 PC_inc (.pc_in(pc_out),.pc_plus4 (pc_plus4));
    Instruction_Memory IMEM (.addr (pc_out),.inst (inst) );
    MuxPC PC_mux (.PCsrc(PCsrc),.pc_plus4(pc_plus4),.branch_target(branch_target),.pc_next(pc_in) );

    assign pc_current = pc_out;

endmodule