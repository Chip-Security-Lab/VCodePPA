//SystemVerilog
// SystemVerilog
// Top-level module for a 10-bit NOT gate using a parameterized sub-module.
module not_gate_10bit_top (
    input wire [9:0] data_in,
    output wire [9:0] data_out
);

    // Instantiate the parameterized 10-bit NOT gate sub-module
    not_gate_param #(
        .DATA_WIDTH(10)
    ) u_not_gate_10bit (
        .in_data(data_in),
        .out_data(data_out)
    );

endmodule

// Parameterized NOT gate sub-module
// Performs bitwise NOT operation on a data bus of configurable width.
module not_gate_param #(
    parameter int DATA_WIDTH = 1
) (
    input wire [DATA_WIDTH-1:0] in_data,
    output wire [DATA_WIDTH-1:0] out_data
);

    // Perform bitwise NOT operation
    assign out_data = ~in_data;

endmodule