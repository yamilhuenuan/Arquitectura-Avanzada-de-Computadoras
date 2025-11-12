// uart_baud_gen.sv
module uart_baud_gen #(
    parameter int unsigned CLK_FREQ  = 100_000_000, // Hz
    parameter int unsigned BAUD      = 115_200,
    parameter int unsigned ACC_WIDTH = 17           // 17 bits -> error ~0.003%
)(
    input  logic clk,
    input  logic rst,         // reset síncrono activo en 1

    output logic baud_tick,   // pulso 1x BAUD
    output logic baud8_tick   // pulso 8x BAUD
);

    // Cálculo con longint para evitar overflow intermedio
    localparam logic [ACC_WIDTH-1:0] INC_1X =
        ( ( longint'(BAUD)   << ACC_WIDTH ) + (CLK_FREQ/2) ) / CLK_FREQ;

    localparam logic [ACC_WIDTH-1:0] INC_8X =
        ( ( longint'(BAUD*8) << ACC_WIDTH ) + (CLK_FREQ/2) ) / CLK_FREQ;

    logic [ACC_WIDTH:0] acc_1x;
    logic [ACC_WIDTH:0] acc_8x;

    always_ff @(posedge clk) begin
        if (rst) begin
            acc_1x <= '0;
            acc_8x <= '0;
        end else begin
            acc_1x <= acc_1x[ACC_WIDTH-1:0] + INC_1X;
            acc_8x <= acc_8x[ACC_WIDTH-1:0] + INC_8X;
        end
    end

    assign baud_tick  = acc_1x[ACC_WIDTH]; // bit de acarreo
    assign baud8_tick = acc_8x[ACC_WIDTH];

endmodule
