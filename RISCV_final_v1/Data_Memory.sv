module data_memory (
    input  logic        clk,
    input  logic        en,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);

    logic [31:0] mem [0:1023]; // 4 KB

    always_ff @(posedge clk) begin
        if (en && we)
            mem[addr[11:2]] <= wdata;
    end

    always_comb begin
        if (en && !we)
            rdata = mem[addr[11:2]];
        else
            rdata = 32'h0000_0000;
    end

endmodule
