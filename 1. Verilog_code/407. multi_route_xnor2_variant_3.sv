//SystemVerilog
//
// Top-level module: multi_route_xnor2
//
module multi_route_xnor2 (
    input  wire [7:0] input1,
    input  wire [7:0] input2,
    input  wire [7:0] input3,
    output wire [7:0] output_xnor
);
    // Internal connections
    wire [7:0] xnor_result1;
    wire [7:0] xnor_result2;
    
    // First XNOR operation between input1 and input2
    bit_xnor_unit xnor_unit1 (
        .a(input1),
        .b(input2),
        .result(xnor_result1)
    );
    
    // Second XNOR operation between input2 and input3
    bit_xnor_unit xnor_unit2 (
        .a(input2),
        .b(input3),
        .result(xnor_result2)
    );
    
    // Final AND operation
    bit_and_unit and_unit (
        .a(xnor_result1),
        .b(xnor_result2),
        .result(output_xnor)
    );
    
endmodule

//
// Parameterized XNOR module
//
module bit_xnor_unit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] result
);
    // Implements a bit-wise XNOR operation
    assign result = ~(a ^ b);
endmodule

//
// Parameterized AND module
//
module bit_and_unit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] result
);
    // Implements a bit-wise AND operation
    assign result = a & b;
endmodule