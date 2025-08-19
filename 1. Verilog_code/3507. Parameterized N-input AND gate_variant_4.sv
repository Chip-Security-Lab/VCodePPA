//SystemVerilog
// SystemVerilog - IEEE 1364-2005 Standard
// Top module: 8-bit subtractor using two's complement addition
module subtractor_8bit (
    input  wire [7:0] a,  // 8-bit input A (minuend)
    input  wire [7:0] b,  // 8-bit input B (subtrahend)
    output wire [7:0] y   // 8-bit output Y (difference)
);
    // Internal connections
    wire [7:0] b_complement;
    
    // Instantiate two's complement module
    twos_complement_8bit u_twos_complement (
        .data_in  (b),
        .data_out (b_complement)
    );
    
    // Instantiate adder module
    adder_8bit u_adder (
        .a        (a),
        .b        (b_complement),
        .sum      (y)
    );
endmodule

// Module to compute two's complement of an 8-bit number
module twos_complement_8bit (
    input  wire [7:0] data_in,   // Input data
    output wire [7:0] data_out   // Two's complement output
);
    // Internal signals
    wire [7:0] inverted_data;
    
    // Invert all bits
    assign inverted_data = ~data_in;
    
    // Add 1 to the inverted value
    assign data_out = inverted_data + 1'b1;
endmodule

// Module for 8-bit addition
module adder_8bit (
    input  wire [7:0] a,    // First operand
    input  wire [7:0] b,    // Second operand
    output wire [7:0] sum   // Sum output
);
    // Simple addition operation
    assign sum = a + b;
endmodule