//========================================================
// Module  : reg_file
//========================================================

module reg_file (
    input  logic clk, rst, reg_wr,
    input  logic [4:0] raddr1, raddr2, waddr,
    input  logic [31:0] wdata,
    output logic [31:0]  rdata1, rdata2   
);

    logic [31:0] register_file[31:0];

    always_comb begin
        rdata1 = (raddr1!=0) ? register_file[raddr1] : 32'd0;
        rdata2 = (raddr2!=0) ? register_file[raddr2] : 32'd0;
    end
    
    integer i;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                register_file[i] <= 32'd0; 
        end
        else if (reg_wr && (|waddr)) begin
            register_file[waddr] <= wdata; 
        end
    end
endmodule