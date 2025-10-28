module uart_rx #(
    parameter DBIT = 8,        // Bits de datos
    parameter SB_TICK = 16     // Ticks para stop bits
)(
    input wire clk, reset,
    input wire rx,             // Línea de recepción serial
    input wire s_tick,         // Tick de muestreo
    output reg rx_done_tick,   // Pulso de dato recibido
    output wire [7:0] dout     // Dato recibido
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

    // Registro de estado
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg <= IDLE;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
        end else begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
        end
    end

    // Lógica de estado siguiente
    always @(*) begin
        state_next = state_reg;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;
        rx_done_tick = 1'b0;

        case (state_reg)
            IDLE:
                if (~rx) begin  // Detectar flanco de bajada (start bit)
                    state_next = START;
                    s_next = 0;
                end

            START:
                if (s_tick) begin
                    if (s_reg == 7) begin  // Muestrear en el medio del bit
                        state_next = DATA;
                        s_next = 0;
                        n_next = 0;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end

            DATA:
                if (s_tick) begin
                    if (s_reg == 15) begin
                        s_next = 0;
                        b_next = {rx, b_reg[7:1]};  // Desplazar hacia la derecha
                        if (n_reg == (DBIT - 1)) begin
                            state_next = STOP;
                        end else begin
                            n_next = n_reg + 1;
                        end
                    end else begin
                        s_next = s_reg + 1;
                    end
                end

            STOP:
                if (s_tick) begin
                    if (s_reg == (SB_TICK - 1)) begin
                        state_next = IDLE;
                        rx_done_tick = 1'b1;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
        endcase
    end

    assign dout = b_reg;

endmodule