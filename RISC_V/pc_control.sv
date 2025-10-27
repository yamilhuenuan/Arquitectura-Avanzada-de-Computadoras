//========================================================
// pc_control_unit.sv
// Genera la señal PCsrc a partir de main_control + branch_unit
//========================================================
`default_nettype none

module pc_control (
    input  logic branch,   // de main_control
    input  logic jump,      // de main_control
    input  logic br_flag,     // de branch_unit
    output logic PCsrc        // a MuxPC
);

    always_comb begin
        PCsrc = (branch && br_flag) || jump ;
    end

endmodule

`default_nettype wire