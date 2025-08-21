// Módulo principal con parámetros configurables y señales correctamente declaradas
module contador_00_99 #(
    parameter integer DIV_COUNT = 50_000_000,  // Divisor para 100 MHz -> 1 Hz
    parameter DISPLAY_TYPE = "ANODE_COMMON"    // "ANODE_COMMON" o "CATHODE_COMMON"
)(
    input  logic clk,
    input  logic reset,
    input  logic enable,
    output logic [6:0] seg,
    output logic [7:0] an      // an[0] = unidades, an[1] = decenas
);

    // Señales internas declaradas explícitamente
    logic clk_div;
    logic [3:0] unidades;
    logic [3:0] decenas;
    logic carry_out;           // Señal de carry cuando llega a 99

    // Divisor de frecuencia
    freq_divider_1hz #(.DIV_COUNT(DIV_COUNT)) div_inst (
        .clk_in(clk),
        .reset(reset),
        .clk_out(clk_div)
    );

    // Contador BCD 0-99 con señal de carry
    bcd_counter_0_99 counter_inst (
        .clk(clk_div),
        .reset(reset),
        .enable(enable),
        .unidades(unidades),
        .decenas(decenas),
        .carry_out(carry_out)
    );

    // Controlador de display con configuración de tipo de display
    display_mux #(.DISPLAY_TYPE(DISPLAY_TYPE))disp_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),       // Ahora recibe la señal enable
        .unidades(unidades),
        .decenas(decenas),
        .seg(seg),
        .an(an)
    );

endmodule


// Divisor de frecuencia mejorado con comentarios
module freq_divider_1hz #(
    parameter integer DIV_COUNT = 50_000_000
)(
    input  logic clk_in,
    input  logic reset,
    output logic clk_out
);
    logic [$clog2(DIV_COUNT)-1:0] count;

    always_ff @(posedge clk_in or posedge reset) begin
        if (reset) begin
            count <= 0;
            clk_out <= 0;
        end else begin
            if (count == DIV_COUNT - 1) begin
                count <= 0;
                clk_out <= ~clk_out;
            end else begin
                count <= count + 1;
            end
        end
    end
endmodule


// Contador BCD con señal de carry out
module bcd_counter_0_99 (
    input  logic clk,
    input  logic reset,
    input  logic enable,
    output logic [3:0] unidades,
    output logic [3:0] decenas,
    output logic carry_out     // Alto cuando llega a 99
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            unidades <= 4'd0;
            decenas <= 4'd0;
            carry_out <= 1'b0;
        end else if (enable) begin
            carry_out <= 1'b0; // Por defecto, carry_out bajo
            
            if (unidades == 4'd9) begin
                unidades <= 4'd0;
                if (decenas == 4'd9) begin
                    decenas <= 4'd0;
                    carry_out <= 1'b1; // Indica que llegó a 99
                end else begin
                    decenas <= decenas + 1;
                end
            end else begin
                unidades <= unidades + 1;
            end
        end
    end
endmodule


// Controlador de display con soporte para ambos tipos de displays
module display_mux #(
    parameter DISPLAY_TYPE = "ANODE_COMMON" // "ANODE_COMMON" o "CATHODE_COMMON"
)(
    input  logic clk,
    input  logic reset,
    input  logic enable,       // Ahora usa la señal enable
    input  logic [3:0] unidades,
    input  logic [3:0] decenas,
    output logic [6:0] seg,
    output logic [7:0] an
);
    // Parámetros para el refresco (~16ms con reloj de 100MHz)
    parameter REFRESH_RATE = 16'd16_000; 
    
    logic [1:0] sel;
    logic [3:0] digit;
    logic [15:0] refresh_count;
    logic [6:0] seg_data;

    // Contador de refresco con enable
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            refresh_count <= 0;
        else if (enable)  // Solo actualiza si está habilitado
            refresh_count <= refresh_count + 1;
    end

    // Selector de dígito basado en el contador de refresco
    assign sel = refresh_count[15:14]; // Cambia cada ~16ms

    // Multiplexación de dígitos y anodos
    always_comb begin
        case (sel)
            2'b00: begin // Unidades
                digit = unidades;
                an = 8'b11111110; // Display 0 activo
            end
            2'b01: begin // Decenas
                digit = decenas;
                an = 8'b11111101; // Display 1 activo
            end
            2'b10: begin // Opcional: Podría ser para centenas si hubiera
                digit = unidades; // Mantenemos mismo valor que 00
                an = 8'b11111110;
            end
            2'b11: begin // Opcional: Podría ser para millares
                digit = decenas; // Mantenemos mismo valor que 01
                an = 8'b11111101;
            end
        endcase
end

    // Codificación 7-segmentos con configuración para tipo de display
    always_comb begin
        case (digit)
            4'd0: seg_data = 7'b0111111; 
            4'd1: seg_data = 7'b0000110;
            4'd2: seg_data = 7'b1011011;
            4'd3: seg_data = 7'b1001111;
            4'd4: seg_data = 7'b1100110;
            4'd5: seg_data = 7'b1101101;
            4'd6: seg_data = 7'b1111101;
            4'd7: seg_data = 7'b0000111;
            4'd8: seg_data = 7'b1111111;
            4'd9: seg_data = 7'b1101111;
            default: seg_data = 7'b0000000;
        endcase
        
        // Invertir salida según tipo de display
        if (DISPLAY_TYPE == "CATHODE_COMMON") begin
            seg = seg_data; // Los 1 encienden los segmentos
        end else begin // ANODE_COMMON (default)
            seg = ~seg_data; // Los 0 encienden los segmentos
        end
    end
endmodule