module fifo_sync #(
    parameter int WIDTH     = 8,
    parameter int DEPTH     = 4,
    parameter int ADDR_BITS = 2
) (
    input  logic              clk,
    input  logic              rst,

    input  logic              wr_en,
    input  logic [WIDTH-1:0]  din,

    input  logic              rd_en,
    output logic [WIDTH-1:0]  dout,

    output logic              empty,
    output logic              full
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_BITS-1:0] wr_ptr, rd_ptr;
    logic [ADDR_BITS:0]   count;

    // Escritura
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end

    // *** LECTURA READ-AHEAD ***
    // dout siempre muestra el elemento apuntado por rd_ptr
    assign dout = mem[rd_ptr];

    // Avance del puntero de lectura
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_ptr <= '0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Contador de ocupación
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= '0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1'b1; // sólo write
                2'b01: count <= count - 1'b1; // sólo read
                default: ;                    // 00 o 11 => no cambia
            endcase
        end
    end

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

endmodule
