//SystemVerilog
//IEEE 1364-2005 SystemVerilog
// Top-level module that instantiates all sub-modules
module Hierarchical_XNOR(
    input [1:0] a, b,
    output [3:0] result
);
    // Optimized direct implementation for better timing and area
    wire [1:0] logic_result;
    
    // Instance of the bit-logic processing module with optimized parameters
    BitLogicProcessor #(
        .OPTIMIZE_LEVEL(2)  // Higher optimization level
    ) bit_processor (
        .a_in(a),
        .b_in(b),
        .logic_result(logic_result)
    );
    
    // Instance of the constant generator module with parameterized values
    ConstantGenerator #(
        .CONSTANT_VALUE(2'b11)
    ) const_gen (
        .const_out(result[3:2])
    );
    
    // Direct assignment for improved timing
    assign result[1:0] = logic_result;
endmodule

// Module to process bit-wise logic operations
module BitLogicProcessor #(
    parameter OPTIMIZE_LEVEL = 1
)(
    input [1:0] a_in, b_in,
    output [1:0] logic_result
);
    generate
        if (OPTIMIZE_LEVEL == 2) begin
            // Vector-based implementation for better resource sharing
            assign logic_result = ~(a_in ^ b_in);
        end else begin
            // Instances of basic XNOR gates for each bit
            XNOR_Enhanced bit0(.a(a_in[0]), .b(b_in[0]), .y(logic_result[0]));
            XNOR_Enhanced bit1(.a(a_in[1]), .b(b_in[1]), .y(logic_result[1]));
        end
    endgenerate
endmodule

// Enhanced XNOR gate with optimized implementation
module XNOR_Enhanced #(
    parameter IMPLEMENTATION_STYLE = "LOOKUP_TABLE"
)(
    input a, b,
    output reg y
);
    // Using always block for lookup-table-based implementation
    // This typically synthesizes to more efficient hardware
    always @(*) begin
        case({a, b})
            2'b00: y = 1'b1;
            2'b01: y = 1'b0;
            2'b10: y = 1'b0;
            2'b11: y = 1'b1;
        endcase
    end
endmodule

// Module to generate constant values
module ConstantGenerator #(
    parameter [1:0] CONSTANT_VALUE = 2'b11
)(
    output [1:0] const_out
);
    // Direct assignment for better timing
    assign const_out = CONSTANT_VALUE;
endmodule