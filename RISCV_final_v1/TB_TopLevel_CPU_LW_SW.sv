//========================================================
// Descripción: Prueba de instrucciones LW y SW.
//              Verifica acceso correcto a RAM, periféricos
//              (LEDs, Switches) y ahora UART mapeada.
//========================================================
`timescale 1ns/1ps


module TB_TopLevel_CPU_LW_SW;

    // --------------------------
    // Señales de estimulación
    // --------------------------
    logic clk;
    logic rst;
    logic [7:0] switches;
    logic [7:0] leds;

    // UART
    logic uart_rx;
    logic uart_tx;

    // --------------------------
    // Señales visibles del DUT
    // --------------------------
    logic [31:0] ALUResult;
    logic [31:0] WriteDataWB;

    // --------------------------
    // Instancia del DUT
    // --------------------------
    TopLevel_CPU uut (
        .clk      (clk),
        .rst      (rst),
        .switches (switches),
        .leds     (leds),
        .uart_rx  (uart_rx),
        .uart_tx  (uart_tx),
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
        rst      = 1;
        switches = 8'b0000_1111; // valor inicial visible
        uart_rx  = 1'b1;         // línea UART en reposo (idle = '1')
        #30;
        rst = 0;

        // Cambiamos switches a mitad de simulación
        #200;
        switches = 8'b1010_1010;
        #200;
        switches = 8'b1111_0000;

        // Podrías agregar más estímulos si querés
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
    initial begin
        $display("===============================================================================================================================================================================");
        $display(" INICIO DE SIMULACIÓN - TEST LW / SW (Gestor de Memoria + GPIO + UART)");
        $display("===============================================================================================================================================================================");
        $display("time(ns) │    PC    │   Inst   │  ALURes  │ WriteDataWB │ MemR │ MemW │ SelA │ SelB │   Addr   │   WData  │   RData  │ LEDs │ SW │ leds_en │ leds_we │ sw_en │  switch_rd │ uart_en │ uart_we │ uart_tx │ uart_wdata │ uart_rdata │ ImmExt    │ rdata1    │ rdata2    │");
        $display("─────────┼──────────┼──────────┼──────────┼─────────────┼──────┼──────┼──────┼──────┼──────────┼──────────┼──────────┼──────┼────┤────────┤─────────┤───────┤────────────┤─────────┤─────────┤─────────┤────────────┤────────────┤───────────┤───────────┤───────────┤");
    end

    // --------------------------
    // Monitoreo continuo
    // --------------------------
    always @(posedge clk) begin
        if (!rst) begin
            $display("%8t │ %08h │ %08h │ %08h │  %08h   │  %1b   │  %1b   │  %1b   │  %1b   │ %08h │ %08h │ %08h │  %02h  │ %02h │    %1b   │    %1b    │   %1b   │   %08h │    %1b    │    %1b    │    %1b    │ %08h    │ %08h    │ %08h │ %08h │ %08h │",
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

                // UART desde mem_manager
                uut.u_memctrl.uart_en,           // enable UART (selección de región)
                uut.u_memctrl.uart_we,           // write enable UART
                uut.uart_tx,                     // línea TX física (hacia PC)
                uut.u_memctrl.uart_wdata,        // dato que la CPU escribe a UART
                uut.uart_rdata,                  // dato que vuelve de la UART a la CPU

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
        $display("===============================================================================================================================================================================");
        $display(" FIN DE SIMULACIÓN - Test LW / SW completo (incluye región UART)");
        $display("===============================================================================================================================================================================");
        $finish;
    end

endmodule


