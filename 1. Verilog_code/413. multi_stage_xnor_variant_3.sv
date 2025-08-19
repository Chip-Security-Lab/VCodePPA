//SystemVerilog
//IEEE 1364-2005 Verilog standard
`timescale 1ns / 1ps

// Top level module
module multi_stage_xnor #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] data_a, 
    input  wire [WIDTH-1:0] data_b,
    output wire [WIDTH-1:0] result
);

    // Direct XNOR implementation for reduced logic depth and better timing
    optimized_xnor_array #(
        .ARRAY_WIDTH(WIDTH)
    ) xnor_array_inst (
        .vector_a(data_a),
        .vector_b(data_b),
        .xnor_result(result)
    );

endmodule

// Optimized multi-bit XNOR comparator with reduced logic stages
module optimized_xnor_array #(
    parameter ARRAY_WIDTH = 4
)(
    input  wire [ARRAY_WIDTH-1:0] vector_a,
    input  wire [ARRAY_WIDTH-1:0] vector_b,
    output wire [ARRAY_WIDTH-1:0] xnor_result
);

    // Implement fast parallel XNOR comparison
    // Using single-stage approach for reduced logic depth
    assign xnor_result = ~(vector_a ^ vector_b);

endmodule