module gpio_switches (
    input  logic        clk,
    input  logic        en,
    input  logic [7:0]  switches,
    output logic [31:0] rdata
);
    always_comb begin
        if (en)
            rdata = {24'b0, switches};
        else
            rdata = 32'h0000_0000;
    end
endmodule
