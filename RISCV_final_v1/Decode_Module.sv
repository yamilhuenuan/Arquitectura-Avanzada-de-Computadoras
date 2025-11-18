//========================================================
// Módulo  : TopLevel_Decode
// Descripción: Integra los módulos de decodificación y control
//              de un procesador RISC-V RV32I.
//========================================================


module Decode_Module (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] Inst,       // instrucción desde memoria de instrucciones
    input  logic [31:0] WriteDataWB,
    input  logic        br_flag,
    output logic [31:0] ImmExt,     // inmediato extendido
    output logic [31:0] rdata1,     // datos leídos de rs1
    output logic [31:0] rdata2,     // datos leídos de rs2
    output logic [3:0]  alu_op,     // operación a ejecutar en la ALU
    output logic        RegWrite,
    output logic        MemWrite,
    output logic        MemRead,
    output logic [1:0]  MemToReg,
    output logic [1:0]  PCsrc,       // control del PC (branch/jump)
    output logic        ALUSrcA,
    output logic        ALUSrcB,
    output logic [1:0]  MemSize,   // ✅ ahora expuesto
    output logic        MemSign 
);

    // Señales internas
    logic [6:0] opcode, funct7;
    logic [2:0] funct3;
    logic [4:0] raddr1, raddr2, waddr;
    logic [2:0] ImmSrc;
    logic [1:0] ALUOp;
    //logic       ALUSrcA, ALUSrcB;
    logic       Branch, Jump, Jump_lr;

    // ---------------- Instruction Parser ----------------
    Instruction_parser u_parser (
        .Inst   (Inst),
        .Funct3 (funct3),
        .raddr1 (raddr1),
        .raddr2 (raddr2),
        .waddr  (waddr),
        .opcode (opcode),
        .Funct7 (funct7)
    );

    // ---------------- Immediate Generator ----------------
    immediate_gen u_immgen (
        .Inst    (Inst),
        .ImmSrcD (ImmSrc),
        .ImmExtD (ImmExt)
    );

    // ---------------- Main Decoder ----------------
    main_decoder u_decoder (
        .opcode   (opcode),
        .funct3   (funct3),
        .RegWrite (RegWrite),
        .ALUSrcA  (ALUSrcA),
        .ALUSrcB  (ALUSrcB),
        .MemWrite (MemWrite),
        .MemRead  (MemRead),
        .Branch   (Branch),
        .Jump     (Jump),
        .Jump_lr     (Jump_lr),
        .MemToReg (MemToReg),
        .ImmSrc   (ImmSrc),
        .ALUOp    (ALUOp),
        .MemSize  (MemSize),
        .MemSign  (MemSign)
    );

    // ---------------- ALU Decoder ----------------
    alu_decoder u_aludec (
        .ALUOp  (ALUOp),
        .funct3 (funct3),
        .funct7 (funct7),
        .alu_op (alu_op)
    );

    // ---------------- Register File ----------------
    reg_file u_regfile (
        .clk    (clk),
        .rst    (rst),
        .reg_wr (RegWrite),
        .raddr1 (raddr1),
        .raddr2 (raddr2),
        .waddr  (waddr),
        .wdata  (WriteDataWB),  // en esta etapa no conectamos memoria/ALU todavía
        .rdata1 (rdata1),
        .rdata2 (rdata2)
    );

    // ---------------- PC Control ----------------
    pc_control u_pcctrl (
        .branch (Branch),
        .jump   (Jump),
        .jalr (Jump_lr),
        .br_flag(br_flag),
        .PCsrc  (PCsrc)
    );

endmodule


