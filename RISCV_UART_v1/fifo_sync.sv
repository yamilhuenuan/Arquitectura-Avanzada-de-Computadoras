// fifo_sync.sv
// FIFO síncrona simple (1 reloj)
// DEPTH debe ser potencia de 2 (ej. 4, 8, ...)

module fifo_sync #(
    parameter int WIDTH     = 8,
    parameter int DEPTH     = 4,
    parameter int ADDR_BITS = 2   // log2(DEPTH), para DEPTH=4 -> 2
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
    logic [ADDR_BITS:0]   count;  // permite contar hasta DEPTH

    // Escritura
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr      <= wr_ptr + 1'b1;
            end
        end
    end

    // Lectura
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_ptr <= '0;
            dout   <= '0;
        end else begin
            if (rd_en && !empty) begin
                dout   <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end
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
                default: /* 00 o 11 => no cambia */ ;
            endcase
        end
    end

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

endmodule
