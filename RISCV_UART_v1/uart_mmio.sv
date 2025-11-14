// uart_mmio.sv
// MMIO de UART con FIFO en RX y TX
// Mapa de registros (ej. base 0x1000_0020 desde mem_manager):
//  - offset 0x0 (reg_sel = 2'b00): UART_DATA
//      * read  -> pop de FIFO RX (si no está vacía)
//      * write -> push a FIFO TX (si no está llena)
//  - offset 0x4 (reg_sel = 2'b01): UART_STATUS
//      bit0 = rx_not_empty   (1 si FIFO RX tiene datos)
//      bit1 = tx_pending     (tx_busy || !tx_fifo_empty)
//      bit2 = tx_fifo_full   (1 si FIFO TX llena)
//      bit3 = rx_fifo_full   (1 si FIFO RX llena)



module uart_mmio (
    input  logic        clk,
    input  logic        rst,

    // MMIO desde mem_manager / CPU
    input  logic        en,        // 1 si la dirección pertenece a la UART
    input  logic        we,        // 1 si es escritura
    input  logic [31:0] addr,      // dirección completa de la CPU
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    // Pines físicos
    input  logic        uart_rx,
    output logic        uart_tx
);

    // ------------------------------------------------------------
    // Decodificación de subregistro dentro del bloque UART
    // addr base = 0x1000_0020 => bits [3:2] = 2'b00 -> DATA
    // addr base + 0x4        => bits [3:2] = 2'b01 -> STATUS
    // ------------------------------------------------------------
    logic [1:0] reg_sel;
    assign reg_sel = addr[3:2];

    // ------------------------------------------------------------
    // 1) Generador de baudios
    //     - baud_tick  : 1× BAUD   (TX)
    //     - baud8_tick : 8× BAUD   (RX)
    // Si tu uart_baud_gen genera baud16_tick en lugar de baud8_tick,
    // ajustá el nombre de la señal en la instancia de uart_rx.
    // ------------------------------------------------------------
    logic baud_tick, baud8_tick;

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

    // ------------------------------------------------------------
    // 2) FRONT-END RX (uart_rx) + FIFO de RX
    // ------------------------------------------------------------
    logic [7:0] rx_data;
    logic       rx_valid;

    // Front-end (sobremuestreo 8×)
    uart_rx #(
        .DATA_BITS(8)
    ) uart_rx_i (
        .clk        (clk),
        .rst        (rst),
        .baud8_tick (baud8_tick),   // si tu RX usa baud16_tick, cambiá este nombre
        .rx         (uart_rx),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid)
    );

    // FIFO de RX
    logic       rx_fifo_wr_en, rx_fifo_rd_en;
    logic [7:0] rx_fifo_din,   rx_fifo_dout;
    logic       rx_fifo_empty, rx_fifo_full;

    assign rx_fifo_din   = rx_data;
    assign rx_fifo_wr_en = rx_valid && !rx_fifo_full; // si está llena, se descarta el byte

    fifo_sync #(
        .WIDTH    (8),
        .DEPTH    (4),
        .ADDR_BITS(2)   // log2(4) = 2
    ) rx_fifo_i (
        .clk   (clk),
        .rst   (rst),
        .wr_en (rx_fifo_wr_en),
        .din   (rx_fifo_din),
        .rd_en (rx_fifo_rd_en),
        .dout  (rx_fifo_dout),
        .empty (rx_fifo_empty),
        .full  (rx_fifo_full)
    );

    // rd_en para FIFO RX cuando la CPU lee UART_DATA
    always_ff @(posedge clk) begin
        if (rst) begin
            rx_fifo_rd_en <= 1'b0;
        end else begin
            rx_fifo_rd_en <= 1'b0; // por defecto
            if (en && !we && reg_sel == 2'd0 && !rx_fifo_empty) begin
                rx_fifo_rd_en <= 1'b1;   // pop de RX FIFO
            end
        end
    end

    // ------------------------------------------------------------
    // 3) FRONT-END TX (uart_tx) + FIFO de TX
    // ------------------------------------------------------------

    // FIFO TX
    logic       tx_fifo_wr_en, tx_fifo_rd_en;
    logic [7:0] tx_fifo_din,   tx_fifo_dout;
    logic       tx_fifo_empty, tx_fifo_full;

    fifo_sync #(
        .WIDTH    (8),
        .DEPTH    (4),
        .ADDR_BITS(2)
    ) tx_fifo_i (
        .clk   (clk),
        .rst   (rst),
        .wr_en (tx_fifo_wr_en),
        .din   (tx_fifo_din),
        .rd_en (tx_fifo_rd_en),
        .dout  (tx_fifo_dout),
        .empty (tx_fifo_empty),
        .full  (tx_fifo_full)
    );

    // Escrituras a UART_DATA -> push a FIFO TX
    always_ff @(posedge clk) begin
        if (rst) begin
            tx_fifo_wr_en <= 1'b0;
            tx_fifo_din   <= 8'h00;
        end else begin
            tx_fifo_wr_en <= 1'b0; // por defecto

            if (en && we && reg_sel == 2'd0) begin
                if (!tx_fifo_full) begin
                    tx_fifo_din   <= wdata[7:0];
                    tx_fifo_wr_en <= 1'b1;
                end
                // Si está llena, se descarta el byte o podrías setear
                // un flag de overflow en STATUS si quisieras.
            end
        end
    end

    // UART TX existente
    logic [7:0] tx_reg;
    logic       tx_start;
    logic       tx_busy;

    uart_tx #(
        .DATA_BITS(8)
    ) uart_tx_i (
        .clk       (clk),
        .rst       (rst),
        .baud_tick (baud_tick),
        .tx_start  (tx_start),
        .tx_data   (tx_reg),
        .tx        (uart_tx),
        .tx_busy   (tx_busy)
    );

    // Lógica para sacar datos de TX FIFO y disparar TX
    always_ff @(posedge clk) begin
        if (rst) begin
            tx_start      <= 1'b0;
            tx_reg        <= 8'h00;
            tx_fifo_rd_en <= 1'b0;
        end else begin
            tx_start      <= 1'b0;
            tx_fifo_rd_en <= 1'b0;

            // Si TX está libre y la FIFO TX no está vacía, enviamos el próximo byte
            if (!tx_busy && !tx_fifo_empty) begin
                tx_reg        <= tx_fifo_dout; // dato a transmitir (dout es "read-ahead")
                tx_start      <= 1'b1;         // pulso a uart_tx
                tx_fifo_rd_en <= 1'b1;         // pop de la FIFO TX
            end
        end
    end

    // ------------------------------------------------------------
    // 4) Lecturas de MMIO (DATA / STATUS)
    // ------------------------------------------------------------
    logic tx_pending;

    always_comb begin
        rdata      = 32'h0000_0000;
        tx_pending = tx_busy || !tx_fifo_empty; // hay algo en TX activo o en cola

        if (en && !we) begin
            unique case (reg_sel)
                // UART_DATA (lectura)
                2'd0: begin
                    // Si la FIFO RX está vacía, devolvemos 0x00 (o el último valor, a elección).
                    // Normalmente el SW primero mira STATUS bit0 (rx_not_empty) antes de leer.
                    rdata = {24'h0, rx_fifo_empty ? 8'h00 : rx_fifo_dout};
                end

                // UART_STATUS
                2'd1: begin
                    // bit0: rx_not_empty  (1 si FIFO RX tiene datos)
                    // bit1: tx_pending    (TX ocupado o FIFO TX no vacía)
                    // bit2: tx_fifo_full  (1 si FIFO TX llena)
                    // bit3: rx_fifo_full  (1 si FIFO RX llena)
                    rdata = {28'h0,
                             rx_fifo_full,
                             tx_fifo_full,
                             tx_pending,
                             !rx_fifo_empty};
                end

                default: rdata = 32'h0;
            endcase
        end
    end

endmodule


