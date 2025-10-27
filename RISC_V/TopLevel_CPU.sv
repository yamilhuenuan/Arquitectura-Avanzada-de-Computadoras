//========================================================
// Módulo  : TopLevel_CPU
// Descripción: CPU RISC-V con Fetch, Decode, Execute, Memory y WriteBack
//========================================================
`default_nettype none

module TopLevel_CPU (
    input  logic clk,
    input  logic rst,
    output logic [31:0] ALUResult,   // salida visible de la ALU
    output logic [31:0] WriteDataWB  // dato que efectivamente vuelve al reg_file
);

    // =====================
    // Señales internas
    // =====================
    logic [31:0] pc_current, inst, branch_target, pc_plus4;
    logic        PCsrc;

    // Decode
    logic [31:0] ImmExt, rdata1, rdata2;
    logic [3:0]  alu_op;
    logic        RegWrite, MemWrite, MemRead;
    logic [1:0]  MemToReg;
    logic        sel_A, sel_B;
    logic [1:0]  MemSize;   // ✅ falta declarar
    logic        MemSign;   // ✅ falta declarar

    // Execute
    logic        br_flag;

    // Memory
    logic [31:0] MemData;

    // =====================
    // Instancias
    // =====================

    // --- FETCH ---
    Fetch_Module u_fetch (
        .clk          (clk),
        .rst          (rst),
        .PCsrc        (PCsrc),
        .branch_target(branch_target),
        .pc_current   (pc_current),
        .inst         (inst)
    );
    assign pc_plus4 = pc_current + 32'd4;

    // --- DECODE ---
    Decode_Module u_decode (
        .clk        (clk),
        .rst        (rst),
        .Inst       (inst),
        .WriteDataWB(WriteDataWB),   // ✅ cerramos el lazo
        .ImmExt     (ImmExt),
        .rdata1     (rdata1),
        .rdata2     (rdata2),
        .alu_op     (alu_op),
        .RegWrite   (RegWrite),
        .MemWrite   (MemWrite),
        .MemRead    (MemRead),
        .MemToReg   (MemToReg),
        .PCsrc      (PCsrc),
        .ALUSrcA    (sel_A),
        .ALUSrcB    (sel_B)
    );

    // --- EXECUTE ---
    Execute_Module u_execute (
        .sel_A     (sel_A),
        .sel_B     (sel_B),
        .funct3    (inst[14:12]),
        .ALUControl(alu_op),
        .PC        (pc_current),
        .rdata1    (rdata1),
        .rdata2    (rdata2),
        .ImmExt    (ImmExt),
        .ALUResult (ALUResult),
        .br_flag   (br_flag)
    );

    // --- MEMORY ---
    Data_Memory u_dmem (
        .clk     (clk),
        .MemRead (MemRead),
        .MemWrite(MemWrite),
        .MemSize (MemSize),      // ✅ ahora viene de Decode
        .MemSign (MemSign), 
        .addr    (ALUResult),
        .wdata   (rdata2),
        .rdata   (MemData)
    );

    // --- WRITEBACK ---
    mux_writeback u_wb_mux (
        .PCplus4  (pc_plus4),
        .ALUResult(ALUResult),
        .MemData  (MemData),
        .MemToReg (MemToReg),
        .WriteData(WriteDataWB)  // ✅ vuelve al reg_file
    );

    // --- Branch Target ---
    assign branch_target = pc_current + ImmExt;

endmodule

`default_nettype wire