//SystemVerilog
// Top-level module
module AsyncResetNOT (
    input rst_n,
    input [3:0] d,
    output [3:0] q
);

    // Instantiate inverter module
    InverterModule inverter (
        .d(d),
        .inv_d(q_inv)
    );

    // Instantiate reset control module
    ResetControl reset_ctrl (
        .rst_n(rst_n),
        .data_in(q_inv),
        .data_out(q)
    );

endmodule

// Inverter submodule
module InverterModule (
    input [3:0] d,
    output [3:0] inv_d
);
    assign inv_d = ~d;
endmodule

// Reset control submodule
module ResetControl (
    input rst_n,
    input [3:0] data_in,
    output reg [3:0] data_out
);
    always @(*) begin
        data_out = rst_n ? data_in : 4'b0000;
    end
endmodule