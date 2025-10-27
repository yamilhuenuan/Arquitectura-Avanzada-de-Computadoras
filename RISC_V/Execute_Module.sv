//========================================================
// TopLevel_Execute.sv
// Integra: mux_selA, mux_selB y ALU
//========================================================
`default_nettype none

module Execute_Module (
    input  logic        sel_A,        // 0: PC, 1: rdata1
    input  logic        sel_B,        // 0: rdata2, 1: ImmExt
    input  logic [2:0]  funct3,       // para branch_unit
    input  logic [3:0]  ALUControl,   // operación ALU
    input  logic [31:0] PC,
    input  logic [31:0] rdata1,
    input  logic [31:0] rdata2,
    input  logic [31:0] ImmExt,
    output logic [31:0] ALUResult,
    output logic        br_flag       // resultado branch (condición)
);

    logic [31:0] SrcA;
    logic [31:0] SrcB;

    branch_unit u_branch_unit (.funct3(funct3),.rs1(rdata1),.rs2(rdata2),.br_flag(br_flag));
    mux_selA u_mux_selA (.sel_A(sel_A),.rdata1(rdata1),.Addr(PC),.SrcA(SrcA));
    mux_selB u_mux_selB (.sel_B(sel_B),.ImmExtD(ImmExt),.rdata2(rdata2),.SrcB(SrcB));
    ALU u_ALU (.SrcA(SrcA),.SrcB(SrcB),.alu_op(ALUControl),.alu_result(ALUResult));

endmodule

`default_nettype wire