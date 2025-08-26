`timescale 1ns/1ps

module tb_contador_de_autos();

    // Parámetros de simulación
    localparam CLK_PERIOD = 10;          // 100 MHz
    localparam DIV_COUNT_SIM = 100;      // Divisor reducido
    localparam DEBOUNCE_COUNT_SIM = 10;  // Debounce reducido
    localparam SIM_TIME_NS = 1000000;    // Tiempo máximo simulación
    
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
    
    // Variables estadísticas
    reg [7:0] contador_esperado = 0;
    integer pruebas_totales = 0;
    integer pruebas_exitosas = 0;
    integer entradas_detectadas = 0;
    integer salidas_detectadas = 0;
    
    // Instancia DUT
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
    
    // Acceso a señales internas
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
    
    // ==============================
    // Tareas de simulación
    // ==============================
    
    // Secuencia de entrada válida
    task secuencia_entrada_valida;
        begin
            S1 = 0; #100;
            S1 = 1; #200;
            S2 = 1; #200;
            S1 = 0; #200;
            S2 = 0; #200;
        end
    endtask
    
    // Secuencia de salida válida
    task secuencia_salida_valida;
        begin
            S2 = 0; #100;
            S2 = 1; #200;
            S1 = 1; #200;
            S2 = 0; #200;
            S1 = 0; #200;
        end
    endtask
    
    // Marcha atrás: sensor=1 -> S1, sensor=0 -> S2
    task secuencia_marcha_atras;
        input sensor;
        begin
            if(sensor) begin
                $display("[%t] Marcha atrás S1 (sin S2)", $time);
                S1 = 0; #100; S1 = 1; #200; S1 = 0; #200;
                S2 = 0;
            end 
            if(sensor) begin
                $display("[%t] Marcha atrás S2 (sin S1)", $time);
                S2 = 0; #100; S2 = 1; #200; S2 = 0; #200;
                S1 = 0;
            end
            $display("[%t] ✅ Marcha atrás completada, contador sin cambio: %d", $time, contador_actual);
        end
    endtask
    
    // Verificar contador
    task verificar_contador;
        input [7:0] valor_esperado;
        begin
            pruebas_totales = pruebas_totales + 1;
            if(contador_actual == valor_esperado) begin
                pruebas_exitosas = pruebas_exitosas + 1;
                $display("[%t] ✅ CONTADOR CORRECTO: Esperado %d, Actual %d", $time, valor_esperado, contador_actual);
            end else begin
                $display("[%t] ❌ ERROR CONTADOR: Esperado %d, Actual %d", $time, valor_esperado, contador_actual);
            end
        end
    endtask
    
    // Forzar contador
    task forzar_contador;
        input [7:0] nuevo_valor;
        begin
            dut.counter_inst.unidades = nuevo_valor % 10;
            dut.counter_inst.decenas = nuevo_valor / 10;
            contador_esperado = nuevo_valor;
            $display("[%t] Contador forzado a: %d", $time, nuevo_valor);
        end
    endtask
    
    // ==============================
    // Monitoreo en tiempo real
    // ==============================
    always @(posedge clk) begin
        if(tb_vehicle_entered) begin
            entradas_detectadas = entradas_detectadas + 1;
            contador_esperado = (contador_esperado < 99) ? contador_esperado + 1 : 99;
        end
        if(tb_vehicle_exited) begin
            salidas_detectadas = salidas_detectadas + 1;
            contador_esperado = (contador_esperado > 0) ? contador_esperado - 1 : 0;
        end
    end
    
    // ==============================
    // Secuencia principal de pruebas
    // ==============================
    initial begin
        // Inicialización
        reset_btn = 1; S1 = 0; S2 = 0; #200;
        reset_btn = 0; #100;
        
        // 1. Entradas válidas
        $display("\nPRUEBA: Secuencias de ENTRADA");
        repeat(20) begin
            secuencia_entrada_valida();
        end
        verificar_contador(20);
        
        // 2. Salidas válidas
        $display("\nPRUEBA: Secuencias de SALIDA");
        repeat(5) begin
            secuencia_salida_valida();
        end
        verificar_contador(5);
        
        // 3. Marcha atrás
        $display("\nPRUEBA: Marcha atrás S1 y S2");
        secuencia_marcha_atras(1);
        secuencia_marcha_atras(0);
        verificar_contador(1); // No cambia
        
        // 4. Saturación
        $display("\nPRUEBA: Saturación del contador");
        forzar_contador(99);
        secuencia_entrada_valida(); // No debe superar 99
        verificar_contador(99);
        secuencia_salida_valida();  // Debe bajar a 98
        verificar_contador(98);
        
        // 5. Reset
        $display("\nPRUEBA: Reset");
        reset_btn = 1; #100;
        reset_btn = 0; #100;
        contador_esperado = 0;
        verificar_contador(0);
        
        // 6. Rebotes y activación simultánea
        $display("\nPRUEBA: Rebotes y activación simultánea");
        S1 = 0; S2 = 0; #10;
        S1 = 1; #5; S1 = 0; #5; S2 = 1; #5; S2 = 0; #5;
        S1 = 1; S2 = 1; #20; S1 = 0; S2 = 0; #10;
        verificar_contador(0);
        
        $display("\nSIMULACIÓN FINALIZADA");
        $finish;
    end
    
    // ==============================
    // GTKWave
    // ==============================
    initial begin
        $dumpfile("contador_de_autos.vcd");
        $dumpvars(0, tb_contador_de_autos);
        $dumpvars(0, dut.vehicle_entered);
        $dumpvars(0, dut.vehicle_exited);
        $dumpvars(0, dut.unidades);
        $dumpvars(0, dut.decenas);
        $dumpvars(0, S1);
        $dumpvars(0, S2);
        $dumpvars(0, reset_btn);
        $dumpvars(0, clk);
    end

endmodule
