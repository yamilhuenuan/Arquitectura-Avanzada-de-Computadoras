// uart_tx.sv (versión corregida con latch de solicitud)
module uart_tx #(
    parameter int DATA_BITS = 8
)(
    input  logic                clk,
    input  logic                rst,
    input  logic                baud_tick,   // 1x BAUD
    input  logic                tx_start,    // pulso 1 ciclo para iniciar
    input  logic [DATA_BITS-1:0] tx_data,    // dato a transmitir

    output logic                tx,          // línea UART
    output logic                tx_busy      // 1 mientras se transmite un frame
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } tx_state_t;

    tx_state_t             state;
    logic [3:0]            bit_index;
    logic [DATA_BITS-1:0]  shifter;

    // Latch de solicitud: recuerda que alguien pidió transmitir
    logic tx_req;

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_req <= 1'b0;
        end else begin
            // capturamos cualquier pulso de tx_start
            if (tx_start)
                tx_req <= 1'b1;
            // una vez que salimos de IDLE, ya consumimos la petición
            if (state != IDLE)
                tx_req <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            bit_index <= '0;
            shifter   <= '0;
            tx        <= 1'b1;  // reposo = 1
            tx_busy   <= 1'b0;
        end else begin
            if (baud_tick) begin
                case (state)
                    IDLE: begin
                        tx      <= 1'b1;
                        tx_busy <= 1'b0;
                        if (tx_req) begin
                            // cargar dato y arrancar en el borde de baud_tick
                            shifter   <= tx_data;
                            bit_index <= '0;
                            tx        <= 1'b0; // start bit
                            tx_busy   <= 1'b1;
                            state     <= START;
                        end
                    end

                    START: begin
                        // luego del start, enviamos primer bit de datos
                        tx        <= shifter[0];
                        shifter   <= {1'b0, shifter[DATA_BITS-1:1]};
                        bit_index <= 1;
                        state     <= DATA;
                    end

                    DATA: begin
                        tx      <= shifter[0];
                        shifter <= {1'b0, shifter[DATA_BITS-1:1]};
                        if (bit_index == DATA_BITS-1) begin
                            state <= STOP;
                        end
                        bit_index <= bit_index + 1;
                    end

                    STOP: begin
                        tx      <= 1'b1;    // stop bit
                        tx_busy <= 1'b0;
                        state   <= IDLE;
                    end

                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule
