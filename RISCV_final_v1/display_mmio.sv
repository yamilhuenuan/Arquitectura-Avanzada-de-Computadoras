// display_mmio.sv

module display_mmio (
    input  logic        clk,
    input  logic        rst,

    // MMIO
    input  logic        en,
    input  logic        we,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    // Salidas fÃ­sicas a la Nexys A7
    output logic [7:0]  an,
    output logic [6:0]  seg
);

    logic [7:0] value_reg;

    // Registro MMIO: guarda el valor a mostrar
    always_ff @(posedge clk) begin
        if (rst) begin
            value_reg <= 8'h00;
        end else if (en && we) begin
            value_reg <= wdata[7:0];
        end
    end

    // Lectura MMIO: devolvemos el Ãºltimo valor escrito (zero-extend)
    always_comb begin
        if (en)
            rdata = {24'h0, value_reg};
        else
            rdata = 32'h0000_0000;
    end

    // Instancia del driver de 7 segmentos que ya probaste
    sevenseg_hex u_disp (
        .clk   (clk),
        .rst   (rst),
        .value (value_reg),
        .an    (an),
        .seg   (seg)
    );

endmodule


