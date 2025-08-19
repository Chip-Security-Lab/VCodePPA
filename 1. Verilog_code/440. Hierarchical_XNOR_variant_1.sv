//SystemVerilog
module Hierarchical_XNOR(
    input [1:0] a, b,
    output [3:0] result
);
    wire [1:0] xnor_result;
    
    // Instantiate XNOR operation submodule for lower bits
    XNOR_Vector #(
        .WIDTH(2)
    ) xnor_vector_inst (
        .a(a),
        .b(b),
        .y(xnor_result)
    );
    
    // Instantiate constant generator for upper bits
    Constant_Generator #(
        .WIDTH(2),
        .VALUE(2'b11)
    ) const_gen_inst (
        .value(result[3:2])
    );
    
    // Connect lower bits
    assign result[1:0] = xnor_result;
endmodule

// Vector XNOR module with skip carry adder implementation
module XNOR_Vector #(
    parameter WIDTH = 2
)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] y
);
    // Intermediate signals for skip carry adder
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum, p;
    
    // Generate propagate signals
    assign p = a | b;
    
    // Skip carry adder implementation
    assign carry[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : adder_bits
            // Sum generation
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
            
            // Carry generation with skip logic
            if (i < WIDTH-1) begin
                assign carry[i+1] = (a[i] & b[i]) | ((a[i] | b[i]) & carry[i]);
            end
        end
    endgenerate
    
    // XNOR implementation using skip carry adder results
    assign y = ~sum;
endmodule

// Constant generator module
module Constant_Generator #(
    parameter WIDTH = 2,
    parameter [WIDTH-1:0] VALUE = {WIDTH{1'b0}}
)(
    output [WIDTH-1:0] value
);
    assign value = VALUE;
endmodule