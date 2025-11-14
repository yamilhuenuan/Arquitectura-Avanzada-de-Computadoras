

module pc_control (
    input  logic branch,     // de main_decoder
    input  logic jump,       // de main_decoder (JAL)
    input  logic jalr,       // de main_decoder (JALR)
    input  logic br_flag,    // de branch_unit
    output logic [1:0] PCsrc // 00=pc+4, 01=branch/jal, 10=jalr
);

    always_comb begin
        // Valor por defecto: ejecución secuencial
        PCsrc = 2'b00;

        if (jalr) begin
            PCsrc = 2'b10;         // JALR → usar rs1+imm
        end
        else if (jump) begin
            PCsrc = 2'b01;         // JAL → usar pc+imm
        end
        else if (branch && br_flag) begin
            PCsrc = 2'b01;         // Branch tomado → usar pc+imm
        end
    end

endmodule



