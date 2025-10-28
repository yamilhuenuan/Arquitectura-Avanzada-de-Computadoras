module uart #(
    parameter DBIT = 8,        // Bits de datos
    parameter SB_TICK = 16,    // Ticks para stop bits
    parameter FIFO_W = 2       // Ancho de dirección FIFO (profundidad = 2^FIFO_W)
)(
    input wire clk, reset,
    // Interfaz UART
    input wire rx,
    output wire tx,
    // Interfaz de usuario
    input wire rd_uart, wr_uart,
    input wire [7:0] w_data,
    output wire [7:0] r_data,
    output wire tx_full, rx_empty
);

    // Señales internas
    wire tick;
    wire rx_done_tick, tx_done_tick;
    wire tx_empty;
    wire [7:0] tx_fifo_out, rx_data_out;
    wire tx_start;

    // Instancia del generador de baud rate
    baud_rate_generator brg (
        .clk(clk),
        .reset(reset),
        .tick(tick)
    );

    // Instancia del receptor UART
    uart_rx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_rx_inst (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .s_tick(tick),
        .rx_done_tick(rx_done_tick),
        .dout(rx_data_out)
    );

    // Instancia del transmisor UART
    uart_tx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_tx_inst (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .s_tick(tick),
        .din(tx_fifo_out),
        .tx_done_tick(tx_done_tick),
        .tx(tx)
    );

    // FIFO para recepción
    fifo #(.DATA_WIDTH(DBIT), .ADDR_WIDTH(FIFO_W)) fifo_rx (
        .clk(clk),
        .reset(reset),
        .rd(rd_uart),
        .wr(rx_done_tick),
        .w_data(rx_data_out),
        .empty(rx_empty),
        .full(),
        .r_data(r_data)
    );

    // FIFO para transmisión
    fifo #(.DATA_WIDTH(DBIT), .ADDR_WIDTH(FIFO_W)) fifo_tx (
        .clk(clk),
        .reset(reset),
        .rd(tx_done_tick),
        .wr(wr_uart),
        .w_data(w_data),
        .empty(tx_empty),
        .full(tx_full),
        .r_data(tx_fifo_out)
    );

    // Control de inicio de transmisión
    assign tx_start = ~tx_empty;

endmodule