
module contador_de_autos #(
    parameter DIV_COUNT = 50000000,  // Divisor para 100 MHz -> 1 Hz
    parameter NUM_DIGITS = 2,       // Número de dígitos del display
    parameter BASE = 10,            // Base decimal
    parameter DEBOUNCE_COUNT = 1000000  // 10 ms para 100 MHz (100,000 ciclos = 1 ms)
)(
    input  logic clk,          // Reloj de la FPGA (100 MHz)
    input  logic reset_btn,    // Botón de reset (activo en alto)
    input  logic S1, S2,       // Sensores (switches)
    output logic [6:0] seg,    // Segmentos del display (a-g)
    output logic [7:0] an      // Ánodos de control
);

    //--------------------------------------------------
    // 1. Señales internas
    //--------------------------------------------------
    logic clk_1hz;             // Reloj dividido (1 Hz)
    logic vehicle_entered;     // Pulso cuando un vehículo entra
    logic vehicle_exited;      // Pulso cuando un vehículo sale
    logic [3:0] unidades;      // Dígito BCD (unidades)
    logic [3:0] decenas;       // Dígito BCD (decenas)
    logic S1_debounced;        // Sensor S1 con antirebotes
    logic S2_debounced;        // Sensor S2 con antirebotes

    //--------------------------------------------------
    // 2. Instancias de submódulos
    //--------------------------------------------------
    // Divisor de frecuencia (opcional, para pruebas)
    freq_divider #(.DIV_COUNT(DIV_COUNT)) div_inst (
        .clk_in(clk),
        .reset(reset_btn),
        .clk_out(clk_1hz)
    );

    // Módulos de antirebotes para los sensores
    debounce #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) debounce_S1 (
        .clk(clk),
        .reset(reset_btn),
        .button_in(S1),
        .button_out(S1_debounced)
    );

    debounce #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) debounce_S2 (
        .clk(clk),
        .reset(reset_btn),
        .button_in(S2),
        .button_out(S2_debounced)
    );

    // Máquina de estados Moore pura para detección de vehículos
    fsm_autos fsm_inst (
        .clk(clk),
        .reset(reset_btn),
        .S1(S1_debounced),
        .S2(S2_debounced),
        .vehicle_entered(vehicle_entered),
        .vehicle_exited(vehicle_exited)
    );

    // Contador BCD de 2 dígitos (0-99)
    bcd_counter counter_inst (
        .clk(clk),
        .reset(reset_btn),
        .inc(vehicle_entered),
        .dec(vehicle_exited),
        .unidades(unidades),
        .decenas(decenas)
    );

    // Controlador del display de 7 segmentos
    display_7seg display_inst (
        .clk(clk),
        .reset(reset_btn),
        .unidades(unidades),
        .decenas(decenas),
        .seg(seg),
        .an(an)
    );

endmodule

//============================================================
// MÓDULO: debounce - Antirebotes
//============================================================
module debounce #(
    parameter DEBOUNCE_COUNT = 1000000  // 10 ms para 100 MHz
)(
    input  logic clk,
    input  logic reset,
    input  logic button_in,
    output logic button_out
);
    logic [19:0] counter;  // Contador para el tiempo de debounce
    logic button_sync;
    logic button_prev;
    
    // Sincronización para evitar metaestabilidad
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            button_sync <= 0;
            button_prev <= 0;
        end else begin
            button_sync <= button_in;
            button_prev <= button_sync;
        end
    end
    
    // Detección de cambio
    logic button_changed;
    assign button_changed = (button_sync != button_prev);
    
    // Máquina de estados para debounce
    typedef enum logic [1:0] {
        IDLE,
        COUNTING,
        STABLE
    } state_t;
    
    state_t estado;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            estado <= IDLE;
            counter <= 0;
            button_out <= 0;
        end else begin
            case (estado)
                IDLE: begin
                    if (button_changed) begin
                        estado <= COUNTING;
                        counter <= 0;
                    end
                end
                
                COUNTING: begin
                    if (counter == DEBOUNCE_COUNT - 1) begin
                        estado <= STABLE;
                        button_out <= button_sync;
                    end else begin
                        counter <= counter + 1;
                    end
                    
                    // Si el botón cambia durante el conteo, reiniciar
                    if (button_changed) begin
                        counter <= 0;
                    end
                end
                
                STABLE: begin
                    estado <= IDLE;
                end
            endcase
        end
    end
endmodule

//============================================================
// MÓDULO: vehicle_fsm_moore (Moore pura) - SIN CAMBIOS
//============================================================
//============================================================
// MÓDULO: vehicle_fsm_moore (Moore pura) - MODIFICADA
//============================================================
module fsm_autos (
    input  logic clk,
    input  logic reset,
    input  logic S1, S2,
    output logic vehicle_entered,
    output logic vehicle_exited
);

    // Estados necesarios para detectar ORDEN de desactivación
    typedef enum logic [2:0] {
        IDLE,               // 000 - Esperando
        S1_ACTIVATED,       // 001 - S1 activado (entrada)
        S2_ACTIVATED,       // 010 - S2 activado (después de S1)
        S1_DEACTIVATED,     // 011 - S1 desactivado (antes que S2)
        S2_DEACTIVATED,     // 100 - S2 desactivado (después de S1) - ENTRADA
        S2_ACTIVATED_F,     // 101 - S2 activado primero (salida)
        S1_ACTIVATED_F,     // 110 - S1 activado (después de S2)
        S2_DEACTIVATED_F    // 111 - S2 desactivado (antes que S1) - SALIDA
    } state_t;

    state_t current_state, next_state;

    // Detección de flancos
    logic S1_prev, S2_prev;
    logic S1_rise, S2_rise, S1_fall, S2_fall;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            S1_prev <= 0;
            S2_prev <= 0;
        end else begin
            S1_prev <= S1;
            S2_prev <= S2;
        end
    end

    assign S1_rise = S1 && !S1_prev;
    assign S2_rise = S2 && !S2_prev;
    assign S1_fall = !S1 && S1_prev;
    assign S2_fall = !S2 && S2_prev;

    // Lógica de transiciones
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (S1_rise && !S2) 
                    next_state = S1_ACTIVATED;      // Posible entrada
                else if (S2_rise && !S1) 
                    next_state = S2_ACTIVATED_F;    // Posible salida
            end

            // Secuencia ENTRADA: S1↑ → S2↑ → S1↓ → S2↓
            S1_ACTIVATED: begin
                if (S2_rise) 
                    next_state = S2_ACTIVATED;      // S2 activado después
                else if (S1_fall) 
                    next_state = IDLE;              // Marcha atrás
            end

            S2_ACTIVATED: begin
                if (S1_fall) 
                    next_state = S1_DEACTIVATED;    // S1 liberado primero
                else if (S2_fall) 
                    next_state = S1_ACTIVATED;      // Marcha atrás
            end

            S1_DEACTIVATED: begin
                if (S2_fall) 
                    next_state = S2_DEACTIVATED;    // S2 liberado después - ENTRADA!
                else if (S1_rise) 
                    next_state = S2_ACTIVATED;      // Vuelve atrás
            end

            // Secuencia SALIDA: S2↑ → S1↑ → S2↓ → S1↓
            S2_ACTIVATED_F: begin
                if (S1_rise) 
                    next_state = S1_ACTIVATED_F;    // S1 activado después
                else if (S2_fall) 
                    next_state = IDLE;              // Marcha atrás
            end

            S1_ACTIVATED_F: begin
                if (S2_fall) 
                    next_state = S2_DEACTIVATED_F;  // S2 liberado primero
                else if (S1_fall) 
                    next_state = S2_ACTIVATED_F;    // Marcha atrás
            end

            S2_DEACTIVATED_F: begin
                if (S1_fall) 
                    next_state = IDLE;              // S1 liberado después - SALIDA!
                else if (S2_rise) 
                    next_state = S1_ACTIVATED_F;    // Vuelve atrás
            end

            default: next_state = IDLE;
        endcase
    end

    // Registro de estado
    always_ff @(posedge clk or posedge reset) begin
        if (reset) 
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

    // Salidas - Pulsos de un ciclo
    assign vehicle_entered = (current_state == S2_DEACTIVATED);
    assign vehicle_exited = (current_state == S2_DEACTIVATED_F && next_state == IDLE);

endmodule
//============================================================
// MÓDULOS AUXILIARES - SIN CAMBIOS
//============================================================

module freq_divider #(
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

module bcd_counter (
    input  logic clk,
    input  logic reset,
    input  logic inc,
    input  logic dec,
    output logic [3:0] unidades,
    output logic [3:0] decenas
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            unidades <= 4'd0;
            decenas <= 4'd0;
        end else begin
            if (inc && !(decenas == 4'd9 && unidades == 4'd9)) begin
                if (unidades == 4'd9) begin
                    unidades <= 4'd0;
                    decenas <= decenas + 1;
                end else begin
                    unidades <= unidades + 1;
                end
            end
            else if (dec && !(decenas == 4'd0 && unidades == 4'd0)) begin
                if (unidades == 4'd0) begin
                    unidades <= 4'd9;
                    decenas <= decenas - 1;
                end else begin
                    unidades <= unidades - 1;
                end
            end
        end
    end
endmodule

module display_7seg (
    input  logic clk,
    input  logic reset,
    input  logic [3:0] unidades,
    input  logic [3:0] decenas,
    output logic [6:0] seg,
    output logic [7:0] an
);
    logic [1:0] sel;
    logic [3:0] digit;
    logic [15:0] refresh_count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) refresh_count <= 0;
        else refresh_count <= refresh_count + 1;
    end

    assign sel = refresh_count[15:14];

    always_comb begin
        case (sel)
            2'b00: begin digit = unidades; an = 8'b11111110; end
            2'b01: begin digit = decenas; an = 8'b11111101; end
            default: begin digit = unidades; an = 8'b11111110; end
        endcase
    end

    always_comb begin
        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;  // Apaga el display para valores inválidos
        endcase
    end
endmodule