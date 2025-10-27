//========================================================
// Módulo  : Data_Memory
// Descripción: Memoria de datos simple para RISC-V RV32I.
//              Compatible con Icarus Verilog.
//========================================================
`default_nettype none

module Data_Memory (
    input  logic        clk,
    input  logic        MemRead,     // habilita lectura
    input  logic        MemWrite,    // habilita escritura
    input  logic [1:0]  MemSize,     // 00=byte, 01=half, 10=word
    input  logic        MemSign,     // 1=signed, 0=unsigned
    input  logic [31:0] addr,        // dirección de acceso
    input  logic [31:0] wdata,       // datos a escribir
    output logic [31:0] rdata        // datos leídos
);

    // Memoria de 1 KB (256 words de 32 bits)
    logic [31:0] mem [0:255];

    // Escritura síncrona
    always_ff @(posedge clk) begin
        if (MemWrite) begin
            case (MemSize)
                2'b00: begin // Byte
                    case (addr[1:0])
                        2'b00: mem[addr[9:2]][7:0]   <= wdata[7:0];
                        2'b01: mem[addr[9:2]][15:8]  <= wdata[7:0];
                        2'b10: mem[addr[9:2]][23:16] <= wdata[7:0];
                        2'b11: mem[addr[9:2]][31:24] <= wdata[7:0];
                    endcase
                end
                2'b01: begin // Halfword
                    case (addr[1])
                        1'b0: mem[addr[9:2]][15:0]  <= wdata[15:0];
                        1'b1: mem[addr[9:2]][31:16] <= wdata[15:0];
                    endcase
                end
                2'b10: mem[addr[9:2]] <= wdata; // Word
            endcase
        end
    end

    // Lectura combinacional (usamos always @(*) para Icarus)
    always @(*) begin
        rdata = 32'd0;

        if (MemRead) begin
            case (MemSize)
                2'b00: begin // Byte
                    case (addr[1:0])
                        2'b00: rdata = MemSign ? {{24{mem[addr[9:2]][7]}},   mem[addr[9:2]][7:0]}   : {24'b0, mem[addr[9:2]][7:0]};
                        2'b01: rdata = MemSign ? {{24{mem[addr[9:2]][15]}},  mem[addr[9:2]][15:8]}  : {24'b0, mem[addr[9:2]][15:8]};
                        2'b10: rdata = MemSign ? {{24{mem[addr[9:2]][23]}},  mem[addr[9:2]][23:16]} : {24'b0, mem[addr[9:2]][23:16]};
                        2'b11: rdata = MemSign ? {{24{mem[addr[9:2]][31]}},  mem[addr[9:2]][31:24]} : {24'b0, mem[addr[9:2]][31:24]};
                    endcase
                end

                2'b01: begin // Halfword
                    case (addr[1])
                        1'b0: rdata = MemSign ? {{16{mem[addr[9:2]][15]}},  mem[addr[9:2]][15:0]}  : {16'b0, mem[addr[9:2]][15:0]};
                        1'b1: rdata = MemSign ? {{16{mem[addr[9:2]][31]}},  mem[addr[9:2]][31:16]} : {16'b0, mem[addr[9:2]][31:16]};
                    endcase
                end

                2'b10: rdata = mem[addr[9:2]]; // Word
                default: rdata = 32'hXXXXXXXX;
            endcase
        end
    end

endmodule

`default_nettype wire