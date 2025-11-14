// uart_baud_gen.sv
// Versión simple compatible con Icarus Verilog



module uart_baud_gen #(
    // Frecuencia de reloj y baudios
    parameter integer CLK_FREQ  = 100_000_000, // Hz
    parameter integer BAUD      = 115_200,
    // Ancho del acumulador
    parameter integer ACC_WIDTH = 17,
    // Incrementos precomputados para 100 MHz / 115200
    // INC_1X  ≈ round(BAUD    * 2^ACC_WIDTH / CLK_FREQ) = 151
    // INC_8X  ≈ round(BAUD*8  * 2^ACC_WIDTH / CLK_FREQ) = 1208
    parameter integer INC_1X    = 151,
    parameter integer INC_8X    = 1208
)(
    input  logic clk,
    input  logic rst,          // reset síncrono activo en 1

    output logic baud_tick,    // pulso a BAUD
    output logic baud8_tick    // pulso a 8*BAUD
);

    // Acumuladores: ACC_WIDTH+1 bits (MSB = carry / tick)
    logic [ACC_WIDTH:0] acc_1x;
    logic [ACC_WIDTH:0] acc_8x;

    always_ff @(posedge clk) begin
        if (rst) begin
            acc_1x <= '0;
            acc_8x <= '0;
        end else begin
            acc_1x <= acc_1x[ACC_WIDTH-1:0] + INC_1X[ACC_WIDTH-1:0];
            acc_8x <= acc_8x[ACC_WIDTH-1:0] + INC_8X[ACC_WIDTH-1:0];
        end
    end

    assign baud_tick  = acc_1x[ACC_WIDTH];
    assign baud8_tick = acc_8x[ACC_WIDTH];

endmodule


