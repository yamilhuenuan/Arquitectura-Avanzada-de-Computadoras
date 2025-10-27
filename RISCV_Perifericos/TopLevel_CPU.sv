//========================================================
// Módulo  : TopLevel_CPU
// Descripción: CPU RISC-V con gestor de memoria, RAM, LEDs,
//              Switches y Display de 7 segmentos
//========================================================
`default_nettype none

module TopLevel_CPU (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  switches,    // Entradas de la Nexys A7
    output logic [7:0]  leds,        // Salidas de la Nexys A7         
    output logic [31:0] ALUResult,
    output logic [31:0] WriteDataWB
);

    // =====================
    // Señales internas
    // =====================
    logic [31:0] pc_current, inst, pc_plus4;
    logic [1:0]  PCsrc;

    // Decode
    logic [31:0] ImmExt, rdata1, rdata2;
    logic [3:0]  alu_op;
    logic        RegWrite, MemWrite, MemRead;
    logic [1:0]  MemToReg;
    logic        sel_A, sel_B;
    logic [1:0]  MemSize;   
    logic        MemSign;   

    // Execute
    logic        br_flag;

    // Memory / Gestor
    logic [31:0] MemData;
    logic [31:0] ram_addr, ram_wdata, ram_rdata;
    logic        ram_en, ram_we;

    // LEDs
    logic [31:0] gpio_leds_wdata, gpio_leds_rdata;
    logic        gpio_leds_en, gpio_leds_we;

    // Switches
    logic [31:0] gpio_sw_rdata;
    logic        gpio_sw_en;


    // =====================
    // FETCH
    // =====================
    Fetch_Module u_fetch (
        .clk          (clk),
        .rst          (rst),
        .PCsrc        (PCsrc),
        .branch_target(ALUResult),
        .jal_target   (ALUResult),
        .pc_current   (pc_current),
        .inst         (inst)
    );
    assign pc_plus4 = pc_current + 32'd4;

    // =====================
    // DECODE
    // =====================
    Decode_Module u_decode (
        .clk        (clk),
        .rst        (rst),
        .Inst       (inst),
        .WriteDataWB(WriteDataWB),  
        .ImmExt     (ImmExt),
        .rdata1     (rdata1),
        .rdata2     (rdata2),
        .alu_op     (alu_op),
        .RegWrite   (RegWrite),
        .MemWrite   (MemWrite),
        .MemRead    (MemRead),
        .MemToReg   (MemToReg),
        .PCsrc      (PCsrc),
        .ALUSrcA    (sel_A),
        .ALUSrcB    (sel_B),
        .br_flag    (br_flag)
    );

    // =====================
    // EXECUTE
    // =====================
    Execute_Module u_execute (
        .sel_A     (sel_A),
        .sel_B     (sel_B),
        .funct3    (inst[14:12]),
        .ALUControl(alu_op),
        .PC        (pc_current),
        .rdata1    (rdata1),
        .rdata2    (rdata2),
        .ImmExt    (ImmExt),
        .ALUResult (ALUResult),
        .br_flag   (br_flag)
    );

    // =====================
    // MEM MANAGER
    // =====================
    mem_manager u_memctrl (
        .addr            (ALUResult),
        .wdata           (rdata2),
        .mem_read        (MemRead),
        .mem_write       (MemWrite),
        .rdata           (MemData),

        // RAM
        .ram_addr        (ram_addr),
        .ram_wdata       (ram_wdata),
        .ram_rdata       (ram_rdata),
        .ram_en          (ram_en),
        .ram_we          (ram_we),

        // GPIO LEDs
        .gpio_leds_wdata (gpio_leds_wdata),
        .gpio_leds_rdata (gpio_leds_rdata),
        .gpio_leds_en    (gpio_leds_en),
        .gpio_leds_we    (gpio_leds_we),

        // GPIO Switches
        .gpio_sw_rdata   (gpio_sw_rdata),
        .gpio_sw_en      (gpio_sw_en)

    );

    // =====================
    // DATA MEMORY (RAM)
    // =====================
    data_memory u_dmem (
        .clk   (clk),
        .en    (ram_en),
        .we    (ram_we),
        .addr  (ram_addr),
        .wdata (ram_wdata),
        .rdata (ram_rdata)
    );

    // =====================
    // GPIO: LEDs
    // =====================
    gpio_leds u_gpio_leds (
        .clk   (clk),
        .en    (gpio_leds_en),
        .we    (gpio_leds_we),
        .wdata (gpio_leds_wdata),
        .rdata (gpio_leds_rdata),
        .leds  (leds)
    );

    // =====================
    // GPIO: Switches
    // =====================
    gpio_switches u_gpio_sw (
        .clk      (clk),
        .en       (gpio_sw_en),
        .switches (switches),
        .rdata    (gpio_sw_rdata)
    );


    // =====================
    // WRITEBACK
    // =====================
    mux_writeback u_wb_mux (
        .PCplus4  (pc_plus4),
        .ALUResult(ALUResult),
        .MemData  (MemData),
        .MemToReg (MemToReg),
        .WriteData(WriteDataWB)
    );

endmodule

`default_nettype wire
