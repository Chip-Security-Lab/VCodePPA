//SystemVerilog
// Top level module: 8-bit Subtractor with delay (implemented using two's complement addition)
`timescale 1ns/1ps

module subtractor_8_delay (
    input wire [7:0] a,  // 8-bit input A (minuend)
    input wire [7:0] b,  // 8-bit input B (subtrahend)
    output wire [7:0] y  // 8-bit output Y (difference)
);
    // Internal connections
    wire [7:0] sub_result;
    
    // Instantiate the subtraction operation submodule
    subtraction_operation_unit sub_op_unit (
        .operand_a(a),
        .operand_b(b),
        .result(sub_result)
    );
    
    // Instantiate the delay handling submodule
    delay_unit #(
        .DELAY_VALUE(5),
        .WIDTH(8)
    ) delay_handler (
        .data_in(sub_result),
        .data_out(y)
    );
    
endmodule

// Submodule for performing subtraction using two's complement addition
module subtraction_operation_unit (
    input wire [7:0] operand_a,   // Minuend
    input wire [7:0] operand_b,   // Subtrahend
    output wire [7:0] result      // Difference result
);
    // Internal signals
    wire [7:0] operand_b_inverted;
    wire [7:0] operand_b_twos_complement;
    wire carry_in;
    
    // Generate two's complement of operand_b
    assign operand_b_inverted = ~operand_b;           // Invert bits (one's complement)
    assign carry_in = 1'b1;                           // Add 1 to make two's complement
    assign operand_b_twos_complement = operand_b_inverted + carry_in;
    
    // Implement subtraction using two's complement addition
    assign result = operand_a + operand_b_twos_complement;
endmodule

// Parameterized delay handling submodule
module delay_unit #(
    parameter DELAY_VALUE = 5,    // Delay value in time units
    parameter WIDTH = 8           // Bit width of signals
)(
    input wire [WIDTH-1:0] data_in,   // Input data
    output reg [WIDTH-1:0] data_out   // Delayed output data
);
    // Apply specified delay to the incoming data
    always @(data_in) begin
        #DELAY_VALUE data_out = data_in;
    end
endmodule