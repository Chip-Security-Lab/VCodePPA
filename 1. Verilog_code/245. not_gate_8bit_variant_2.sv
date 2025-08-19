//SystemVerilog
// SystemVerilog
// Top module: 8-bit NOT gate using a parameterized sub-module
module not_gate_8bit (
    input wire [7:0] A,
    output wire [7:0] Y
);

    // Instantiate the generic NOT gate module for 8 bits
    generic_not_gate #(.WIDTH(8))
    not_gate_inst (
        .in_data(A),
        .out_data(Y)
    );

endmodule

// Generic Sub-module: Parameterized NOT gate
// Performs logical NOT operation on a vector of specified width
module generic_not_gate #(
    parameter WIDTH = 1
) (
    input wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);

    assign out_data = ~in_data;

endmodule