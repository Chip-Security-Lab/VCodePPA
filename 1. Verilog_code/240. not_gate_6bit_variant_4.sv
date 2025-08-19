//SystemVerilog
// SystemVerilog
// Top-level module for a 6-bit NOT gate using a vectorized submodule
module not_gate_6bit (
    input wire [5:0] data_in,
    output wire [5:0] data_out
);

    // Instantiate the vectorized 6-bit NOT gate submodule
    not_gate_vectorized #(.DATA_WIDTH(6))
    not_inst (
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule

// Submodule for a vectorized NOT gate
// This module performs bitwise NOT operation on a vector of specified width.
module not_gate_vectorized #(
    parameter int DATA_WIDTH = 1 // Parameter for the width of the data vector
) (
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);

    // Perform bitwise NOT operation
    assign data_out = ~data_in;

endmodule