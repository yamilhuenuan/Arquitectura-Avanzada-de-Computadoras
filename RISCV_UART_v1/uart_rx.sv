// uart_rx.sv
module uart_rx #(
    parameter int DATA_BITS = 8
)(
    input  logic                clk,
    input  logic                rst,
    input  logic                baud8_tick, // 8x BAUD
    input  logic                rx,         // línea UART

    output logic [DATA_BITS-1:0] rx_data,
    output logic                rx_valid    // pulso 1 clk por byte recibido
);

    // 1) Sincronización + pequeño filtro sobre rx
    logic [1:0] rx_sync;
    logic [1:0] rx_cnt;
    logic       rx_bit; // versión "limpia"

    always_ff @(posedge clk) begin
        if (rst) begin
            rx_sync <= 2'b11;
            rx_cnt  <= 2'b11;
            rx_bit  <= 1'b1;
        end else if (baud8_tick) begin
            rx_sync <= {rx_sync[0], rx};

            if (rx_sync[1] && rx_cnt != 2'b11)
                rx_cnt <= rx_cnt + 1;
            else if (!rx_sync[1] && rx_cnt != 2'b00)
                rx_cnt <= rx_cnt - 1;

            if (rx_cnt == 2'b00)
                rx_bit <= 1'b0;
            else if (rx_cnt == 2'b11)
                rx_bit <= 1'b1;
        end
    end

    // 2) Máquina de estados de recepción
    typedef enum logic [1:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP
    } rx_state_t;

    rx_state_t            state;
    logic [2:0]           os_cnt;   // 0..7 (oversampling)
    logic [2:0]           bit_idx;
    logic [DATA_BITS-1:0] data_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= RX_IDLE;
            os_cnt   <= '0;
            bit_idx  <= '0;
            rx_data  <= '0;
            data_reg <= '0;
            rx_valid <= 1'b0;
        end else begin
            rx_valid <= 1'b0; // default

            if (baud8_tick) begin
                case (state)
                    RX_IDLE: begin
                        os_cnt  <= '0;
                        bit_idx <= '0;
                        if (rx_bit == 1'b0) begin
                            // posible start
                            state <= RX_START;
                        end
                    end

                    RX_START: begin
                        os_cnt <= os_cnt + 1;
                        // muestreo en mitad del bit de start (~4/8)
                        if (os_cnt == 3'd3) begin
                            if (rx_bit == 1'b0) begin
                                // start confirmado
                                os_cnt  <= '0;
                                bit_idx <= '0;
                                state   <= RX_DATA;
                            end else begin
                                // falso start
                                state <= RX_IDLE;
                            end
                        end
                    end

                    RX_DATA: begin
                        os_cnt <= os_cnt + 1;
                        if (os_cnt == 3'd7) begin
                            // muestreo al final del bit
                            data_reg[bit_idx] <= rx_bit; // LSB primero
                            os_cnt <= '0;
                            if (bit_idx == DATA_BITS-1) begin
                                state <= RX_STOP;
                            end
                            bit_idx <= bit_idx + 1;
                        end
                    end

                    RX_STOP: begin
                        os_cnt <= os_cnt + 1;
                        if (os_cnt == 3'd7) begin
                            rx_data  <= data_reg;
                            rx_valid <= 1'b1; // nuevo byte listo
                            os_cnt   <= '0;
                            state    <= RX_IDLE;
                        end
                    end

                    default: state <= RX_IDLE;
                endcase
            end
        end
    end

endmodule
