//========================================================
// Descripción: Prueba de instrucciones LW y SW.
//              Verifica acceso correcto a RAM y periféricos.
//========================================================
`timescale 1ns/1ps
`default_nettype none

module TB_TopLevel_CPU_LW_SW;

    // --------------------------
    // Señales de estimulación
    // --------------------------
    logic clk;
    logic rst;
    logic [7:0] switches;
    logic [7:0] leds;

    // --------------------------
    // Señales visibles del DUT
    // --------------------------
    logic [31:0] ALUResult;
    logic [31:0] WriteDataWB;

    // --------------------------
    // Instancia del DUT
    // --------------------------
    TopLevel_CPU uut (
        .clk(clk),
        .rst(rst),
        .switches(switches),
        .leds(leds),
        .ALUResult(ALUResult),
        .WriteDataWB(WriteDataWB)
    );

    // --------------------------
    // Reloj: 100 MHz (10 ns)
    // --------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --------------------------
    // Reset y estimulación
    // --------------------------
    initial begin
        rst = 1;
        switches = 8'b00001111; // valor inicial visible
        #30;
        rst = 0;

        // Cambiamos switches a mitad de simulación
        #200;
        switches = 8'b10101010;
        #200;
        switches = 8'b11110000;
    end

    // --------------------------
    // Archivo de waveform
    // --------------------------
    initial begin
        $dumpfile("TB_TopLevel_CPU_LW_SW.vcd");
        $dumpvars(0, TB_TopLevel_CPU_LW_SW);
    end

    // --------------------------
    // Encabezado tabla
    // --------------------------
// --------------------------
// Encabezado alineado
// --------------------------
initial begin
    $display("=============================================================");
    $display(" INICIO DE SIMULACIÓN - TEST LW / SW (Gestor de Memoria)");
    $display("=============================================================");
    $display("time(ns) │    PC    │   Inst   │  ALURes  │ WriteDataWB │ MemR │ MemW │ SelA │ SelB │   Addr   │   WData  │   RData  │ LEDs │ SW │  leds_en │ leds_we │ sw_en │   switch   │   ImmExt   │   rdata1   │   rdata2   │");
    $display("─────────┼──────────┼──────────┼──────────┼─────────────┼──────┼──────┼──────┼──────┼──────────┼──────────┼──────────┼──────┼────┤──────────┤─────────┤───────┤────────────┤────────────┤────────────┤────────────┤");
end

// --------------------------
// Monitoreo continuo
// --------------------------
always @(posedge clk) begin
    if (!rst) begin
        $display("%8t │ %08h │ %08h │ %08h │  %08h   │  %1b   │  %1b   │  %1b   │  %1b   │ %08h │ %08h │ %08h │  %02h  │ %02h │     %1b    │     %1b   │   %1b   │   %08h │   %08h │   %08h │   %08h │",
            $time,                           // tiempo
            uut.pc_current,                  // PC
            uut.inst,                        // Instrucción actual
            uut.ALUResult,                   // Resultado de ALU
            uut.WriteDataWB,                 // Dato writeback
            uut.MemRead,                     // Control MemRead
            uut.MemWrite,                    // Control MemWrite
            uut.u_execute.sel_A,             // Selector A
            uut.u_execute.sel_B,             // Selector B
            uut.ALUResult,                   // Addr (dirección efectiva)
            uut.rdata2,                      // WData (dato a escribir)
            uut.MemData,                     // RData (dato leído)
            uut.leds,                        // Estado de LEDs
            uut.switches,                    // Estado de switches
            uut.u_memctrl.gpio_leds_en,      // Señal enable LEDs
            uut.u_memctrl.gpio_leds_we,      // Señal write enable LEDs
            uut.u_memctrl.gpio_sw_en,        // Señal enable switches
            uut.u_memctrl.gpio_sw_rdata,     // Valor de switches leído
            uut.u_execute.ImmExt,            // Inmediato extendido
            uut.u_decode.rdata1,             // Valor rs1
            uut.u_decode.rdata2              // Valor rs2
        );
    end
end


    // --------------------------
    // Fin de simulación
    // --------------------------
    initial begin
        #2000;
        $display("=============================================================");
        $display(" FIN DE SIMULACIÓN - Test LW / SW completo");
        $display("=============================================================");
        $finish;
    end

endmodule

`default_nettype wire