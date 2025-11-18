
module sevenseg_hex (
    input  logic        clk,      // 100 MHz
    input  logic        rst,

    // Valor dinámico (2 últimos dígitos)
    input  logic [7:0]  value,

    // Nexys A7: 8 dígitos, ánodo común, activos en bajo
    output logic [7:0]  an,       // AN7..AN0
    output logic [6:0]  seg       // CA..CG, activos en bajo
);

    // ----------------------------------------------------
    // Multiplexor de dígitos
    // ----------------------------------------------------
    logic [15:0] div_cnt;
    logic [2:0]  digit_sel;   // 0..7

    always_ff @(posedge clk) begin
        if (rst) begin
            div_cnt   <= 16'd0;
            digit_sel <= 3'd0;
        end else begin
            div_cnt <= div_cnt + 16'd1;
            if (div_cnt == 16'd0)
                digit_sel <= digit_sel + 3'd1;
        end
    end

    // Nibbles dinámicos
    logic [3:0] nib_lo, nib_hi;
    assign nib_lo = value[3:0];
    assign nib_hi = value[7:4];

    // ----------------------------------------------------
    // DECODER hex -> segmentos (activos en bajo)
    // ----------------------------------------------------
    function automatic logic [6:0] hex_to_seg (input logic [3:0] x);
        begin
            unique case (x)
                4'h0: hex_to_seg = 7'b1000000;
                4'h1: hex_to_seg = 7'b1111001;
                4'h2: hex_to_seg = 7'b0100100;
                4'h3: hex_to_seg = 7'b0110000;
                4'h4: hex_to_seg = 7'b0011001;
                4'h5: hex_to_seg = 7'b0010010;
                4'h6: hex_to_seg = 7'b0000010;
                4'h7: hex_to_seg = 7'b1111000;
                4'h8: hex_to_seg = 7'b0000000;
                4'h9: hex_to_seg = 7'b0010000;
                4'hA: hex_to_seg = 7'b0001000;
                4'hB: hex_to_seg = 7'b0000011;
                4'hC: hex_to_seg = 7'b1000110;
                4'hD: hex_to_seg = 7'b0100001;
                4'hE: hex_to_seg = 7'b0000110;
                4'hF: hex_to_seg = 7'b0001110;
                default: hex_to_seg = 7'b1111111; // blanco
            endcase
        end
    endfunction

    // Patrones fijos para 'R' y 'U' (activos en bajo)
    localparam logic [6:0] SEG_R   = 7'b1001110;  // aproximación de 'r'
    localparam logic [6:0] SEG_U   = 7'b1000001;  // aproximación de 'U'
    localparam logic [6:0] SEG_OFF = 7'b1111111;  // todo apagado

    // ----------------------------------------------------
    // Lógica de multiplexado RU32 + dinámico
    // ----------------------------------------------------
    always_comb begin
        // default: todo apagado
        an  = 8'b1111_1111;
        seg = SEG_OFF;

        unique case (digit_sel)
            3'd0: begin
                // AN0 (más a la derecha): nibble bajo dinámico
                an  = 8'b1111_1110;
                seg = hex_to_seg(nib_lo);
            end

            3'd1: begin
                // AN1: nibble alto dinámico
                an  = 8'b1111_1101;
                seg = hex_to_seg(nib_hi);
            end

            3'd2: begin
                // AN2: apagado
                an  = 8'b1111_1011;
                seg = SEG_OFF;
            end

            3'd3: begin
                // AN3: apagado
                an  = 8'b1111_0111;
                seg = SEG_OFF;
            end

            3'd4: begin
                // AN4: '2' fija
                an  = 8'b1110_1111;
                seg = hex_to_seg(4'd2);
            end

            3'd5: begin
                // AN5: '3' fija
                an  = 8'b1101_1111;
                seg = hex_to_seg(4'd3);
            end

            3'd6: begin
                // AN6: 'U' fija
                an  = 8'b1011_1111;
                seg = SEG_U;
            end

            3'd7: begin
                // AN7: 'r' fija
                an  = 8'b0111_1111;
                seg = SEG_R;
            end
        endcase
    end

endmodule