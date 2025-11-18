module gpio_leds (
    input  logic        clk,      // reloj del sistema
    input  logic        en,       // enable del periférico (activo cuando dir ∈ LEDs)
    input  logic        we,       // write enable (activo en SW)
    input  logic [31:0] wdata,    // dato a escribir
    output logic [31:0] rdata,    // dato leído (valor actual de LEDs)
    output logic [7:0]  leds      // salida física a la placa
);

    // Registro interno del estado de los LEDs
    logic [7:0] reg_leds;

    // Escritura sincronizada al flanco positivo del reloj
    always_ff @(posedge clk) begin
        if (en && we)
            reg_leds <= wdata[7:0];
    end

    // Lectura combinacional (valor actual de los LEDs)
    assign rdata = {24'b0, reg_leds};

    // Salida a los LEDs físicos
    assign leds = reg_leds;

endmodule