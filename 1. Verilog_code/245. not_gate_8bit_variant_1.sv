//SystemVerilog

// not_gate_param - Performs bitwise NOT operation on a parameterized width
// This module provides a more flexible and reusable NOT gate
module not_gate_param #(
    parameter DATA_WIDTH = 1
) (
    input wire [DATA_WIDTH-1:0] in_data,
    output wire [DATA_WIDTH-1:0] out_data
);
    // Perform bitwise NOT operation on the input data
    assign out_data = ~in_data;
endmodule

// not_gate_8bit_top - Top level module for 8-bit NOT gate using a parameterized sub-module
// This module instantiates a single parameterized NOT gate module for 8 bits
module not_gate_8bit (
    input wire [7:0] A,
    output wire [7:0] Y
);

    // Instantiate the parameterized NOT gate module for 8 bits
    not_gate_param #(
        .DATA_WIDTH(8) // Set the data width to 8 bits
    ) not_inst (
        .in_data(A),  // Connect the input A to the sub-module's input
        .out_data(Y)  // Connect the output Y to the sub-module's output
    );

endmodule