//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module
module xor_port_style #(
    parameter DATA_WIDTH = 1
)(
    input  [DATA_WIDTH-1:0] a,
    input  [DATA_WIDTH-1:0] b,
    output [DATA_WIDTH-1:0] y
);
    // Instantiate the conditional inverting subtractor module
    conditional_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) cond_sub_inst (
        .in_a(a),
        .in_b(b),
        .out_result(y)
    );
endmodule

// Conditional inverting subtractor submodule that implements XOR functionality
module conditional_subtractor #(
    parameter DATA_WIDTH = 1
)(
    input  [DATA_WIDTH-1:0] in_a,
    input  [DATA_WIDTH-1:0] in_b,
    output [DATA_WIDTH-1:0] out_result
);
    // Internal signals
    wire [DATA_WIDTH-1:0] inverted_a;
    wire [DATA_WIDTH-1:0] inverted_b;
    wire [DATA_WIDTH-1:0] sub_result_a_b;
    wire [DATA_WIDTH-1:0] sub_result_b_a;
    
    // Generate inverted inputs
    assign inverted_a = ~in_a;
    assign inverted_b = ~in_b;
    
    // Conditional subtraction based on input values
    // If in_b is 1, use inverted_a, otherwise use in_a
    assign sub_result_a_b = (in_b) ? inverted_a : in_a;
    
    // If in_a is 1, use inverted_b, otherwise use in_b
    assign sub_result_b_a = (in_a) ? inverted_b : in_b;
    
    // Final result selection (functionally equivalent to XOR)
    assign out_result = (in_a & in_b) ? 1'b0 : (in_a | in_b);
endmodule