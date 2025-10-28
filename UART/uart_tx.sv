module uart_tx #(
    parameter DBIT = 8,        // Bits de datos
    parameter SB_TICK = 16     // Ticks para stop bits
)(
    input wire clk, reset,
    input wire tx_start,       // Señal de inicio de transmisión
    input wire s_tick,         // Tick de baud rate
    input wire [7:0] din,      // Dato a transmitir
    output reg tx_done_tick,   // Pulso de transmisión completada
    output wire tx             // Línea de transmisión serial
);

    // Estados
    localparam [1:0]
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11;

    reg [1:0] state_reg, state_next;
    reg [3:0] s_reg, s_next;        // Contador de ticks
    reg [2:0] n_reg, n_next;        // Contador de bits
    reg [7:0] b_reg, b_next;        // Registro de desplazamiento
    reg tx_reg, tx_next;

    // Registro de estado
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg <= IDLE;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
            tx_reg <= 1'b1;
        end else begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
            tx_reg <= tx_next;
        end
    end

    // Lógica de estado siguiente
    always @(*) begin
        state_next = state_reg;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;
        tx_next = tx_reg;
        tx_done_tick = 1'b0;

        case (state_reg)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    state_next = START;
                    s_next = 0;
                    b_next = din;
                end
            end

            START: begin
                tx_next = 1'b0;  // Start bit
                if (s_tick) begin
                    if (s_reg == 15) begin
                        state_next = DATA;
                        s_next = 0;
                        n_next = 0;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            DATA: begin
                tx_next = b_reg[0];  // Bit LSB primero
                if (s_tick) begin
                    if (s_reg == 15) begin
                        s_next = 0;
                        b_next = {1'b0, b_reg[7:1]};  // Desplazar hacia la derecha
                        if (n_reg == (DBIT - 1)) begin
                            state_next = STOP;
                        end else begin
                            n_next = n_reg + 1;
                        end
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;  // Stop bit
                if (s_tick) begin
                    if (s_reg == (SB_TICK - 1)) begin
                        state_next = IDLE;
                        tx_done_tick = 1'b1;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end
        endcase
    end

    assign tx = tx_reg;

endmodule