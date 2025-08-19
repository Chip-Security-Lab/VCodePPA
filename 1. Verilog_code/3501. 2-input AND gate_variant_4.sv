//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: subtractor_top.v
// Description: Parameterized subtractor using two's complement addition
// Author: FPGA Optimization Expert
// Version: 1.0
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module subtractor_top #(
    parameter WIDTH = 2  // Configurable bit width
)(
    input  wire [WIDTH-1:0] a,      // Minuend
    input  wire [WIDTH-1:0] b,      // Subtrahend
    output wire [WIDTH-1:0] diff    // Difference
);

    // Instantiate the core subtractor module
    subtractor_core #(
        .WIDTH(WIDTH)
    ) subtractor_inst (
        .a(a),
        .b(b),
        .diff(diff)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: subtractor_core.v
// Description: Core subtractor functionality implemented using two's complement
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module subtractor_core #(
    parameter WIDTH = 2  // Bit width
)(
    input  wire [WIDTH-1:0] a,      // Minuend
    input  wire [WIDTH-1:0] b,      // Subtrahend
    output wire [WIDTH-1:0] diff    // Difference
);
    
    // Implement subtraction using two's complement adder
    twos_complement_adder #(
        .WIDTH(WIDTH)
    ) adder_inst (
        .a(a),
        .b(b),
        .sum(diff)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: twos_complement_adder.v
// Description: Implements subtraction using two's complement addition
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module twos_complement_adder #(
    parameter WIDTH = 2  // Bit width
)(
    input  wire [WIDTH-1:0] a,      // First operand 
    input  wire [WIDTH-1:0] b,      // Second operand to be subtracted
    output wire [WIDTH-1:0] sum     // Result of a - b
);

    wire [WIDTH-1:0] b_inverted;    // Inverted b
    wire [WIDTH:0] temp_sum;        // Sum with carry
    
    // Invert all bits of b (one's complement)
    assign b_inverted = ~b;
    
    // Add one to inverted b and add to a (two's complement addition)
    assign temp_sum = a + b_inverted + 1'b1;
    
    // Final result is the lower WIDTH bits of temp_sum
    assign sum = temp_sum[WIDTH-1:0];
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: and_gate_top.v
// Description: Parameterized AND gate top module
// Author: FPGA Optimization Expert
// Version: 1.0
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module and_gate_top #(
    parameter INPUT_WIDTH = 2  // Configurable number of inputs
)(
    input  wire [INPUT_WIDTH-1:0] in,  // Vector of inputs
    output wire out                    // Single output
);

    // Instantiate the core AND gate module
    and_gate_core #(
        .WIDTH(INPUT_WIDTH)
    ) and_gate_inst (
        .inputs(in),
        .result(out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: and_gate_core.v
// Description: Core AND operation functionality with parameterized width
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module and_gate_core #(
    parameter WIDTH = 2  // Number of inputs to AND together
)(
    input  wire [WIDTH-1:0] inputs,  // Input vector
    output wire result               // Output result
);
    
    // Internal implementation of the AND reduction
    and_reduction #(
        .WIDTH(WIDTH)
    ) and_red_inst (
        .data_in(inputs),
        .data_out(result)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: and_reduction.v
// Description: AND reduction module - combines all inputs with AND operation
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module and_reduction #(
    parameter WIDTH = 2  // Input width
)(
    input  wire [WIDTH-1:0] data_in,  // Input data vector
    output wire data_out               // Output - AND of all inputs
);

    // Reduce all inputs with AND operation
    assign data_out = &data_in;
    
endmodule