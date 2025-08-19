//SystemVerilog
// Top-level module
module AsyncResetNOT(
    input rst_n,
    input [3:0] d,
    output [3:0] q
);

    // Instantiate inverter module
    Inverter inverter_inst (
        .d(d),
        .q_inv(q_inv)
    );

    // Instantiate reset controller module
    ResetController reset_ctrl_inst (
        .rst_n(rst_n),
        .data_in(q_inv),
        .data_out(q)
    );

endmodule

// Inverter module - performs bitwise inversion
module Inverter(
    input [3:0] d,
    output [3:0] q_inv
);
    assign q_inv = ~d;
endmodule

// Reset controller module - handles reset functionality
module ResetController(
    input rst_n,
    input [3:0] data_in,
    output reg [3:0] data_out
);
    always @(*) begin
        data_out = rst_n ? data_in : 4'b0000;
    end
endmodule