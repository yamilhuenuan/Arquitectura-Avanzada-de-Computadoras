module uart_tb;

    reg clk, reset;
    reg rx, rd_uart, wr_uart;
    reg [7:0] w_data;
    wire tx, tx_full, rx_empty;
    wire [7:0] r_data;

    // Instancia UART
    uart uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx),
        .rd_uart(rd_uart),
        .wr_uart(wr_uart),
        .w_data(w_data),
        .r_data(r_data),
        .tx_full(tx_full),
        .rx_empty(rx_empty)
    );

    // Generador de reloj (50 MHz)
    always #10 clk = ~clk;

    // Tarea para enviar caracter por UART
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            // Start bit
            rx = 1'b0;
            #8680;

            // Bits de datos (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #8680;
            end

            // Stop bit
            rx = 1'b1;
            #8680;
        end
    endtask

    // Tarea para enviar string - Versión Verilog
    task send_string;
        input [8*50:0] str;
        integer i;
        reg [7:0] char;
        begin
            $display(">> ENVIANDO: '%s'", str);
            for (i = 0; i < 50; i = i + 1) begin
                // Extraer caracter del string (big-endian)
                char = str >> ((49-i)*8);
                if (char != 8'h00) begin
                    send_byte(char);
                    #20000; // Pausa entre bytes
                end
            end
        end
    endtask

    // Tarea para transmitir dato
    task transmit_byte;
        input [7:0] data;
        begin
            wait(!tx_full);
            w_data = data;
            wr_uart = 1'b1;
            #40;
            wr_uart = 1'b0;
            #40;
        end
    endtask

    // Tarea para transmitir string - Versión Verilog
    task transmit_string;
        input [8*50:0] str;
        integer i;
        reg [7:0] char;
        begin
            $display("<< TRANSMITIENDO: '%s'", str);
            for (i = 0; i < 50; i = i + 1) begin
                // Extraer caracter del string (big-endian)
                char = str >> ((49-i)*8);
                if (char != 8'h00) begin
                    transmit_byte(char);
                    #5000; // Esperar entre bytes
                end
            end
        end
    endtask

    // Monitoreo automático de datos recibidos
    always @(posedge uut.rx_done_tick) begin
        #10; // Pequeño delay para estabilizar
        $display("✓ RECIBIDO: 0x%h ('%c')", uut.rx_data_out, uut.rx_data_out);
    end

    // Monitoreo de transmisiones completadas
    always @(posedge uut.tx_done_tick) begin
        $display("✓ TRANSMITIDO: Byte completado");
    end

    // Secuencia de prueba principal
    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, uart_tb);
        
        // Inicialización
        clk = 1'b0;
        reset = 1'b1;
        rx = 1'b1;
        rd_uart = 1'b0;
        wr_uart = 1'b0;
        w_data = 8'h0;

        $display("========================================");
        $display("🚀 INICIANDO PRUEBAS UART");
        $display("========================================");

        // Reset
        #100 reset = 1'b0;
        #1000;

        // Prueba 1: Recepción de string simple
        $display("\n--- PRUEBA 1: Recepción ---");
        send_string("HOLA");
        #100000;

        // Leer datos recibidos
        $display("\n--- Leyendo FIFO RX ---");
        while (!rx_empty) begin
            rd_uart = 1'b1;
            #40;
            $display("📥 LEIDO: 0x%h ('%c')", r_data, r_data);
            rd_uart = 1'b0;
            #40;
        end

        #20000;

        // Prueba 2: Transmisión simple
        $display("\n--- PRUEBA 2: Transmisión ---");
        transmit_string("TEST");
        #100000;

        #20000;

        // Prueba 3: Caracteres individuales
        $display("\n--- PRUEBA 3: Caracteres individuales ---");
        send_byte("A");
        send_byte("B"); 
        send_byte("C");
        #50000;

        $display("\n--- Leyendo caracteres ---");
        while (!rx_empty) begin
            rd_uart = 1'b1;
            #40;
            $display("📥 LEIDO: 0x%h ('%c')", r_data, r_data);
            rd_uart = 1'b0;
            #40;
        end

        #20000;

        // Prueba 4: Números
        $display("\n--- PRUEBA 4: Números ---");
        send_string("123");
        #50000;

        $display("\n--- Leyendo números ---");
        while (!rx_empty) begin
            rd_uart = 1'b1;
            #40;
            $display("📥 LEIDO: 0x%h ('%c')", r_data, r_data);
            rd_uart = 1'b0;
            #40;
        end

        #20000;

        // Prueba final: String más largo
        $display("\n--- PRUEBA FINAL: String completo ---");
        send_string("UART OK!");
        #80000;

        $display("\n--- Datos finales ---");
        while (!rx_empty) begin
            rd_uart = 1'b1;
            #40;
            $display("📥 LEIDO: 0x%h ('%c')", r_data, r_data);
            rd_uart = 1'b0;
            #40;
        end

        $display("\n========================================");
        $display("✅ PRUEBAS COMPLETADAS");
        $display("========================================");
        #1000;
        $finish;
    end

endmodule