module mem_manager (
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        mem_read,
    input  logic        mem_write,
    output logic [31:0] rdata,

    // RAM
    output logic [31:0] ram_addr,
    output logic [31:0] ram_wdata,
    input  logic [31:0] ram_rdata,
    output logic        ram_en,
    output logic        ram_we,

    // GPIO LEDs
    output logic [31:0] gpio_leds_wdata,
    input  logic [31:0] gpio_leds_rdata,
    output logic        gpio_leds_en,
    output logic        gpio_leds_we,

    // GPIO Switches
    input  logic [31:0] gpio_sw_rdata,
    output logic        gpio_sw_en,

    // UART MMIO
    output logic        uart_en,
    output logic        uart_we,
    output logic [31:0] uart_wdata,
    input  logic [31:0] uart_rdata
);

    always_comb begin
        // ---------------- Defaults ----------------
        ram_en        = 1'b0;
        ram_we        = 1'b0;

        gpio_leds_en  = 1'b0;
        gpio_leds_we  = 1'b0;

        gpio_sw_en    = 1'b0;

        uart_en       = 1'b0;
        uart_we       = 1'b0;

        rdata         = 32'h0000_0000;

        ram_addr        = addr;
        ram_wdata       = wdata;
        gpio_leds_wdata = wdata;
        uart_wdata      = wdata;

        // ----------- Decodificación de direcciones -----------

        if (addr < 32'h0001_0000) begin
            // RAM 0x0000_0000 - 0x0000_FFFF
            ram_en = mem_read | mem_write;
            ram_we = mem_write;
            rdata  = ram_rdata;

        end else if (addr >= 32'h1000_0000 && addr < 32'h1000_0010) begin
            // LEDs 0x1000_0000
            gpio_leds_en = mem_read | mem_write;
            gpio_leds_we = mem_write;
            rdata        = gpio_leds_rdata;

        end else if (addr >= 32'h1000_0010 && addr < 32'h1000_0020) begin
            // Switches 0x1000_0010
            gpio_sw_en = mem_read;
            rdata      = gpio_sw_rdata;

        end else if (addr >= 32'h1000_0020 && addr < 32'h1000_0030) begin
            // UART 0x1000_0020 - 0x1000_002F
            // (subregistros los selecciona el uart_mmio con addr[3:2])
            uart_en = mem_read | mem_write;
            uart_we = mem_write;
            rdata   = uart_rdata;
        end
    end

endmodule
