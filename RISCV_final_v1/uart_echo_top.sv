// uart_echo_top.sv
module uart_echo_top (
    input  logic       clk,      // 100 MHz
    input  logic       btn_reset,    // botón, activo en 0
    input  logic       uart_rx,  // desde PC (USB-UART)
    output logic       uart_tx,  // hacia PC
    output logic [7:0] leds      // último byte recibido
);

    
    logic rst = btn_reset; // interno activo en 1

    // -------------------------------------------------------------------------
    // Generador de baudios
    // -------------------------------------------------------------------------
    logic baud_tick;
    logic baud8_tick;

    uart_baud_gen #(
        .CLK_FREQ (100_000_000),
        .BAUD     (115_200),
        .ACC_WIDTH(17)
    ) baud_gen_i (
        .clk        (clk),
        .rst        (rst),
        .baud_tick  (baud_tick),
        .baud8_tick (baud8_tick)
    );

    // -------------------------------------------------------------------------
    // Receptor UART
    // -------------------------------------------------------------------------
    logic [7:0] rx_data;
    logic       rx_valid;

    uart_rx #(
        .DATA_BITS(8)
    ) uart_rx_i (
        .clk        (clk),
        .rst        (rst),
        .baud8_tick (baud8_tick),
        .rx         (uart_rx),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid)
    );

    // -------------------------------------------------------------------------
    // Transmisor UART (eco)
    // -------------------------------------------------------------------------
    logic       tx_start;
    logic       tx_busy;
    logic [7:0] tx_data;

    uart_tx #(
        .DATA_BITS(8)
    ) uart_tx_i (
        .clk       (clk),
        .rst       (rst),
        .baud_tick (baud_tick),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .tx        (uart_tx),
        .tx_busy   (tx_busy)
    );

    // -------------------------------------------------------------------------
    // Lógica de eco + LEDs
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            leds    <= 8'h00;
            tx_data <= 8'h00;
            tx_start <= 1'b0;
        end else begin
            tx_start <= 1'b0; // default

            if (rx_valid) begin
                leds <= rx_data; // debug en LEDs

                if (!tx_busy) begin
                    tx_data  <= rx_data;
                    tx_start <= 1'b1; // un ciclo
                end
            end
        end
    end

endmodule
