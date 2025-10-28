module baud_rate_generator #(
    parameter M = 27  // Para 115200 baudios @ 50MHz: 50,000,000 / (16 * 115200) ≈ 27
)(
    input wire clk, reset,
    output wire tick
);

    reg [4:0] counter;

    always @(posedge clk or posedge reset) begin
        if (reset)
            counter <= 0;
        else if (counter == M-1)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    assign tick = (counter == M-1);

endmodule