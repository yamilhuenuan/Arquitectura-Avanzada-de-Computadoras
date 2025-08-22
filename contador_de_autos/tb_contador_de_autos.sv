`timescale 1ns/1ps

module tb_contador_de_autos();

    // Parámetros de simulación
    localparam CLK_PERIOD = 10;          // 100 MHz (10 ns)
    localparam DIV_COUNT_SIM = 100;      // Divisor reducido para simulación rápida
    localparam DEBOUNCE_COUNT_SIM = 10;  // Debounce reducido para simulación
    localparam SIM_TIME_NS = 50000;      // 50 μs de simulación
    
    // Señales de prueba
    reg clk;
    reg reset_btn;
    reg S1, S2;
    wire [6:0] seg;
    wire [7:0] an;
    
    // Variables internas para monitoreo
    wire [3:0] tb_unidades, tb_decenas;
    wire tb_vehicle_entered, tb_vehicle_exited;
    reg [7:0] contador_actual;
    wire S1_debounced, S2_debounced;
    
    // Variables para estadísticas y verificación
    reg [7:0] contador_esperado = 0;
    integer pruebas_totales = 0;
    integer pruebas_exitosas = 0;
    integer entradas_detectadas = 0;
    integer salidas_detectadas = 0;
    
    // Instancia del DUT
    contador_de_autos #(
        .DIV_COUNT(DIV_COUNT_SIM),
        .DEBOUNCE_COUNT(DEBOUNCE_COUNT_SIM)
    ) dut (
        .clk(clk),
        .reset_btn(reset_btn),
        .S1(S1),
        .S2(S2),
        .seg(seg),
        .an(an)
    );
    
    // Acceso a señales internas para verificación
    assign tb_unidades = dut.unidades;
    assign tb_decenas = dut.decenas;
    assign tb_vehicle_entered = dut.vehicle_entered;
    assign tb_vehicle_exited = dut.vehicle_exited;
    assign contador_actual = {tb_decenas, tb_unidades};
    assign S1_debounced = dut.S1_debounced;
    assign S2_debounced = dut.S2_debounced;
    
    // Generación de reloj
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Tarea para simular secuencia de entrada válida
    task secuencia_entrada_valida;
        begin
            $display("[%t] Iniciando secuencia ENTRADA: S1↑ → S2↑ → S1↓ → S2↓", $time);
            
            // S1↑ → S2↑ → S1↓ → S2↓
            S1 = 0; #100;
            S1 = 1; #200;  // S1 activado
            S2 = 1; #200;  // S2 activado
            S1 = 0; #200;  // S1 desactivado
            S2 = 0; #200;  // S2 desactivado
            #300;
            
            $display("[%t] Secuencia ENTRADA completada", $time);
        end
    endtask
    
    // Tarea para simular secuencia de salida válida
    task secuencia_salida_valida;
        begin
            $display("[%t] Iniciando secuencia SALIDA: S2↑ → S1↑ → S2↓ → S1↓", $time);
            
            // S2↑ → S1↑ → S2↓ → S1↓
            S2 = 0; #100;
            S2 = 1; #200;  // S2 activado
            S1 = 1; #200;  // S1 activado
            S2 = 0; #200;  // S2 desactivado
            S1 = 0; #200;  // S1 desactivado
            #300;
            
            $display("[%t] Secuencia SALIDA completada", $time);
        end
    endtask
    
    // Tarea para simular marcha atrás
    task secuencia_marcha_atras;
        input sensor;
        begin
            if (sensor) begin
                $display("[%t] Marcha atrás S1: S1↑ → S1↓", $time);
                // Marcha atrás en S1
                S1 = 0; #100;
                S1 = 1; #200;  // S1 activado
                S1 = 0; #200;  // S1 desactivado (sin S2)
                #300;
            end else begin
                $display("[%t] Marcha atrás S2: S2↑ → S2↓", $time);
                // Marcha atrás en S2
                S2 = 0; #100;
                S2 = 1; #200;  // S2 activado
                S2 = 0; #200;  // S2 desactivado (sin S1)
                #300;
            end
        end
    endtask
    
    // Monitoreo en tiempo real con verificación automática
    always @(posedge clk) begin
        if (tb_vehicle_entered) begin
            entradas_detectadas = entradas_detectadas + 1;
            contador_esperado = contador_esperado + 1;
            if (contador_esperado > 99) contador_esperado = 99;
            $display("[%t] ✅ PULSO ENTRADA detectado! Contador: %d%d", $time, tb_decenas, tb_unidades);
            
            // Verificación automática
            #10; // Pequeño delay para estabilización
            if (contador_actual == contador_esperado) begin
                $display("[%t] ✅ CONTADOR CORRECTO después de entrada: %d", $time, contador_actual);
            end else begin
                $display("[%t] ❌ ERROR CONTADOR: Esperado %d, Actual %d", 
                        $time, contador_esperado, contador_actual);
            end
        end
        
        if (tb_vehicle_exited) begin
            salidas_detectadas = salidas_detectadas + 1;
            if (contador_esperado > 0) contador_esperado = contador_esperado - 1;
            $display("[%t] ✅ PULSO SALIDA detectado! Contador: %d%d", $time, tb_decenas, tb_unidades);
            
            // Verificación automática
            #10; // Pequeño delay para estabilización
            if (contador_actual == contador_esperado) begin
                $display("[%t] ✅ CONTADOR CORRECTO después de salida: %d", $time, contador_actual);
            end else begin
                $display("[%t] ❌ ERROR CONTADOR: Esperado %d, Actual %d", 
                        $time, contador_esperado, contador_actual);
            end
        end
    end
    
    // Debug de estados FSM (comentado hasta verificar nombres exactos)
    /*
    always @(posedge clk) begin
        if (dut.fsm_inst.estado_actual != dut.fsm_inst.estado_siguiente) begin
            $display("[%t] FSM: %d -> %d, S1: %b, S2: %b", $time,
                    dut.fsm_inst.estado_actual,
                    dut.fsm_inst.estado_siguiente,
                    S1_debounced,
                    S2_debounced);
        end
    end
    */
    
    // Tarea para verificar contador
    task verificar_contador;
        input [7:0] valor_esperado;
        begin
            pruebas_totales = pruebas_totales + 1;
            if (contador_actual == valor_esperado) begin
                pruebas_exitosas = pruebas_exitosas + 1;
                $display("[%t] ✅ CONTADOR VERIFICADO: Esperado %d, Actual %d", 
                        $time, valor_esperado, contador_actual);
            end else begin
                $display("[%t] ❌ ERROR CONTADOR: Esperado %d, Actual %d", 
                        $time, valor_esperado, contador_actual);
            end
        end
    endtask
    
    // Tarea para forzar contador (modificación directa de registros)
    task forzar_contador;
        input [7:0] nuevo_valor;
        begin
            dut.counter_inst.unidades = nuevo_valor % 10;
            dut.counter_inst.decenas = nuevo_valor / 10;
            contador_esperado = nuevo_valor;
            $display("[%t] Contador forzado a: %d", $time, nuevo_valor);
        end
    endtask
    
    // Secuencia principal de pruebas
    initial begin
        // Inicialización
        $display("==============================================");
        $display("INICIANDO SIMULACIÓN DEL CONTADOR DE AUTOS");
        $display("==============================================");
        
        reset_btn = 1;
        S1 = 0;
        S2 = 0;
        #200;
        
        // Liberar reset
        reset_btn = 0;
        #100;
        
        $display("[%t] Reset liberado, contador inicial: %d%d", $time, tb_decenas, tb_unidades);
        verificar_contador(0);
        
        // ==============================================
        // Prueba 1: Secuencias de entrada válidas
        // ==============================================
        $display("\n[%t] PRUEBA 1: 3 SECUENCIAS DE ENTRADA VÁLIDAS", $time);
        
        repeat(3) begin
            secuencia_entrada_valida();
            if (tb_vehicle_entered) begin
                $display("[%t] ✅ Entrada contada correctamente", $time);
            end else begin
                $display("[%t] ❌ ERROR: Entrada NO detectada", $time);
            end
        end
        verificar_contador(3);
        
        // ==============================================
        // Prueba 2: Marchas atrás (no deben afectar)
        // ==============================================
        $display("\n[%t] PRUEBA 2: MARCHAS ATRÁS (no deben contar)", $time);
        
        repeat(2) begin
            secuencia_marcha_atras(1); // Marcha atrás S1
            secuencia_marcha_atras(0); // Marcha atrás S2
            
            if (!tb_vehicle_entered && !tb_vehicle_exited) begin
                $display("[%t] ✅ Marcha atrás ignorada correctamente", $time);
            end else begin
                $display("[%t] ❌ ERROR: Marcha atrás contó incorrectamente", $time);
            end
        end
        
        // Verificar que no cambió por marchas atrás
        verificar_contador(3);
        
        // ==============================================
        // Prueba 3: Secuencias de salida válidas
        // ==============================================
        $display("\n[%t] PRUEBA 3: 2 SECUENCIAS DE SALIDA VÁLIDAS", $time);
        
        repeat(2) begin
            secuencia_salida_valida();
            if (tb_vehicle_exited) begin
                $display("[%t] ✅ Salida contada correctamente", $time);
            end else begin
                $display("[%t] ❌ ERROR: Salida NO detectada", $time);
            end
        end
        
        // Verificación final
        verificar_contador(1);
        
        // ==============================================
        // Prueba 4: Secuencias inválidas y ruido
        // ==============================================
        $display("\n[%t] PRUEBA 4: SECUENCIAS INVÁLIDAS Y RUIDO", $time);
        
        // Secuencia demasiado rápida (posible rebote)
        $display("[%t] Probando secuencia rápida con posible rebote", $time);
        S1 = 0; S2 = 0; #50;
        S1 = 1; #5; S2 = 1; #5; S1 = 0; #5; S2 = 0; #100;
        
        // Activación simultánea (ruido/error)
        $display("[%t] Probando activación simultánea de sensores", $time);
        S1 = 0; S2 = 0; #100;
        S1 = 1; S2 = 1; #100;  // Ambos sensores activos
        S1 = 0; S2 = 0; #100;
        
        // Verificar que no se contó
        if (!tb_vehicle_entered && !tb_vehicle_exited) begin
            $display("[%t] ✅ Secuencias inválidas ignoradas correctamente", $time);
            pruebas_exitosas = pruebas_exitosas + 1;
        end else begin
            $display("[%t] ❌ ERROR: Secuencias inválidas fueron contadas", $time);
        end
        pruebas_totales = pruebas_totales + 1;
        
        verificar_contador(1);
        
        // ==============================================
        // Prueba 5: Saturación del contador
        // ==============================================
        $display("\n[%t] PRUEBA 5: SATURACIÓN DEL CONTADOR", $time);
        
        // Forzar contador a 99
        forzar_contador(99);
        verificar_contador(99);
        
        // Intentar entrada (debería saturar en 99)
        secuencia_entrada_valida();
        if (contador_actual == 99) begin
            $display("[%t] ✅ Contador se saturó correctamente en 99", $time);
            pruebas_exitosas = pruebas_exitosas + 1;
        end else begin
            $display("[%t] ❌ ERROR: Contador no se saturó correctamente", $time);
        end
        pruebas_totales = pruebas_totales + 1;
        
        // Intentar salida (debería bajar a 98)
        secuencia_salida_valida();
        if (contador_actual == 98) begin
            $display("[%t] ✅ Contador bajó correctamente a 98", $time);
            pruebas_exitosas = pruebas_exitosas + 1;
        end else begin
            $display("[%t] ❌ ERROR: Contador no bajó correctamente", $time);
        end
        pruebas_totales = pruebas_totales + 1;
        
        // ==============================================
        // Prueba 6: Reset y verificación final
        // ==============================================
        $display("\n[%t] PRUEBA 6: RESET FINAL", $time);
        
        reset_btn = 1;
        #100;
        reset_btn = 0;
        #100;
        
        contador_esperado = 0;
        if (contador_actual == 0) begin
            $display("[%t] ✅ Reset funcionó correctamente", $time);
            pruebas_exitosas = pruebas_exitosas + 1;
        end else begin
            $display("[%t] ❌ ERROR: Reset falló, contador: %d", $time, contador_actual);
        end
        pruebas_totales = pruebas_totales + 1;
        
        // ==============================================
        // Finalización con reporte detallado
        // ==============================================
        $display("\n[%t] ==============================================", $time);
        $display("[%t] SIMULACIÓN COMPLETADA", $time);
        $display("[%t] ==============================================", $time);
        $display("[%t] RESUMEN ESTADÍSTICAS:", $time);
        $display("[%t]   Pruebas totales:    %d", $time, pruebas_totales);
        $display("[%t]   Pruebas exitosas:   %d", $time, pruebas_exitosas);
        $display("[%t]   Tasa de éxito:      %.2f%%", $time, (pruebas_exitosas*100.0)/pruebas_totales);
        $display("[%t]   Entradas detectadas: %d", $time, entradas_detectadas);
        $display("[%t]   Salidas detectadas:  %d", $time, salidas_detectadas);
        $display("[%t]   Contador final:      %d%d", $time, tb_decenas, tb_unidades);
        $display("[%t] ==============================================", $time);
        
        if (pruebas_exitosas == pruebas_totales) begin
            $display("[%t] 🎉 TODAS LAS PRUEBAS EXITOSAS!", $time);
        end else begin
            $display("[%t] ⚠️  ALGUNAS PRUEBAS FALLARON", $time);
        end
        $display("[%t] ==============================================", $time);
        
        #1000;
        $finish;
    end
    
    // Volcado de señales para GTKWave (solo señales principales)
    initial begin
        $dumpfile("contador_de_autos.vcd");
        $dumpvars(0, tb_contador_de_autos);
        
        // Señales clave
        $dumpvars(0, dut.vehicle_entered);
        $dumpvars(0, dut.vehicle_exited);
        $dumpvars(0, dut.unidades);
        $dumpvars(0, dut.decenas);
        $dumpvars(0, dut.S1_debounced);
        $dumpvars(0, dut.S2_debounced);
        $dumpvars(0, S1);
        $dumpvars(0, S2);
        $dumpvars(0, reset_btn);
        $dumpvars(0, clk);
    end
    
    // Terminar simulación después de tiempo máximo
    initial begin
        #SIM_TIME_NS;
        $display("[%t] ⏰ Tiempo de simulación agotado", $time);
        $display("[%t] Pruebas completadas: %d/%d", $time, pruebas_exitosas, pruebas_totales);
        $finish;
    end
    
endmodule