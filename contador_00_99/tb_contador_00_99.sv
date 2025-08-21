`timescale 1ns / 1ps

module tb_contador_00_99;

    // Parámetros
    parameter DIV_COUNT = 500; // Valor reducido para simulaciones más rápidas
    parameter CLK_PERIOD = 10; // 100 MHz (10 ns periodo)
    
    // Señales
    reg clk;
    reg reset;
    reg enable;
    wire [6:0] seg;
    wire [7:0] an;
    
    // Instancia del DUT
    contador_00_99 #(
        .DIV_COUNT(DIV_COUNT),
        .DISPLAY_TYPE("ANODE_COMMON")
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .seg(seg),
        .an(an)
    );
    
    // Generación de reloj
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Tareas útiles
    task assert_reset;
        begin
            reset = 1'b1;
            enable = 1'b0;
            #(CLK_PERIOD * 2);
            reset = 1'b0;
            #(CLK_PERIOD);
        end
    endtask
    
    // Procedimiento de prueba
    initial begin
        // Inicialización
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_contador_00_99);
        $display("Iniciando simulación...");
        
        // Test 1: Reset
        $display("Test 1: Verificar reset");
        assert_reset();
        
        // Test 2: Conteo básico
        $display("Test 2: Conteo básico (enable=1)");
        enable = 1'b1;
        
        // Test 3: Verificar enable
        $display("Test 3: Verificar enable");
        #(DIV_COUNT * CLK_PERIOD * 2);
        enable = 1'b0;
        #(DIV_COUNT * CLK_PERIOD * 2);
        enable = 1'b1;
        
        // Test 4: Verificar carry out y rollover (99->00)
        $display("Test 4: Verificar conteo hasta 99");
        
        // Esperar hasta que el contador llegue naturalmente a 99
        wait(dut.counter_inst.decenas == 4'd9 && dut.counter_inst.unidades == 4'd9);
        $display("Contador llegó a 99 naturalmente");
        
        // Esperar un flanco de reloj para que se active carry_out
        #(CLK_PERIOD); 
        
        if (dut.counter_inst.carry_out !== 1'b1)
            $error("Carry out no se activó al llegar a 99");
        else
            $display("Carry out activado correctamente");
        
        // Esperar un ciclo más para ver el rollover
        #(DIV_COUNT * CLK_PERIOD);
        
        // Verificar que volvió a 00
        if (dut.counter_inst.unidades !== 4'd0 || dut.counter_inst.decenas !== 4'd0)
            $error("Error en rollover - no volvió a 00");
        else
            $display("Rollover a 00 verificado correctamente");
        
        // Finalizar simulación
        #(CLK_PERIOD * 10);
        $display("Simulación completada");
        $finish;
    end
    
    // Monitoreo de señales
    always @(posedge clk) begin
        $display("Tiempo: %0t | Enable: %b | Unidades: %d | Decenas: %d | Carry: %b | Anodos: %b | Segmentos: %b",
            $time, enable, 
            dut.counter_inst.unidades, 
            dut.counter_inst.decenas,
            dut.counter_inst.carry_out,
            an, seg);
    end

endmodule