//========================================================
// Módulo  : Top_control_unit
// Descripción: Une main_control, alu_control, branch_unit
//              y load_store_unit.
//========================================================


module Top_control_unit (
    // Campos de la instrucción
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,

    // Operandos desde el Banco de Registros
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,

    // Resultados de la ALU
    input  logic [31:0] alu_result,

    // Interfaz con Memoria de Datos
    input  logic [31:0] data_mem_rd,
    output logic [31:0] addr,
    output logic [31:0] data_wr,
    output logic [31:0] data_rd_ext,
    output logic [3:0]  mask,

    // Señales de control al Datapath
    output logic        RegWrite,
    output logic        ALUSrcA,
    output logic        ALUSrcB,
    output logic        MemWrite,
    output logic        MemRead,
    output logic        Branch,
    output logic        Jump,
    output logic [1:0]  MemToReg,
    output logic [2:0]  ImmSrc,
    output logic [3:0]  alu_op,
    output logic        br_flag
);

    // Señal interna de ALUOp (main_control -> alu_control)
    logic [1:0] ALUOp;

    // ---------------------------
    // Instanciación de módulos
    // ---------------------------

    // Unidad de Control Principal
    main_control u_main_control (
        .opcode   (opcode),
        .RegWrite (RegWrite),
        .ALUSrcA  (ALUSrcA),
        .ALUSrcB  (ALUSrcB),
        .MemWrite (MemWrite),
        .MemRead  (MemRead),
        .Branch   (Branch),
        .Jump     (Jump),
        .MemToReg (MemToReg),
        .ImmSrc   (ImmSrc),
        .ALUOp    (ALUOp)
    );

    // Unidad de Control de la ALU
    alu_control u_alu_control (
        .ALUOp   (ALUOp),
        .funct3  (funct3),
        .funct7  (funct7),
        .alu_op  (alu_op)
    );

    // Unidad de Branch
    branch_unit u_branch_unit (
        .funct3   (funct3),
        .rs1      (rs1),
        .rs2      (rs2),
        .br_flag  (br_flag)
    );

    // Unidad de Load/Store
    load_store_unit u_load_store_unit (
        .funct3      (funct3),
        .opcode      (opcode),
        .alu_result  (alu_result),
        .rs2_data    (rs2),
        .data_mem_rd (data_mem_rd),
        .mask        (mask),
        .addr        (addr),
        .data_wr     (data_wr),
        .data_rd_ext (data_rd_ext)
    );

endmodule


