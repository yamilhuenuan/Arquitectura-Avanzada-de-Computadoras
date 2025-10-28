module fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wire clk, reset,
    input wire rd, wr,
    input wire [DATA_WIDTH-1:0] w_data,
    output wire empty, full,
    output wire [DATA_WIDTH-1:0] r_data
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] array_reg [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] w_ptr_reg, w_ptr_next;
    reg [ADDR_WIDTH-1:0] r_ptr_reg, r_ptr_next;
    reg full_reg, empty_reg, full_next, empty_next;

    wire wr_en;

    // Escritura sincrónica
    always @(posedge clk) begin
        if (wr_en)
            array_reg[w_ptr_reg] <= w_data;
    end

    // Registros de estado
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            full_reg <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg <= full_next;
            empty_reg <= empty_next;
        end
    end

    // Lógica de estado siguiente
    always @(*) begin
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next = full_reg;
        empty_next = empty_reg;

        case ({wr, rd})
            2'b01: // Lectura
                if (~empty_reg) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next = 1'b0;
                    if (r_ptr_next == w_ptr_reg)
                        empty_next = 1'b1;
                end

            2'b10: // Escritura
                if (~full_reg) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 1'b0;
                    if (w_ptr_next == r_ptr_reg)
                        full_next = 1'b1;
                end

            2'b11: // Lectura y escritura simultánea
                begin
                    w_ptr_next = w_ptr_reg + 1;
                    r_ptr_next = r_ptr_reg + 1;
                end
        endcase
    end

    assign wr_en = wr & ~full_reg;
    assign r_data = array_reg[r_ptr_reg];
    assign full = full_reg;
    assign empty = empty_reg;

endmodule