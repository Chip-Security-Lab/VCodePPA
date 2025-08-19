//SystemVerilog
// Top level module: 4-bit 4-input AND gate with hierarchical design
module and_gate_4bit (
    input  wire [3:0] a,  // 4-bit input A
    input  wire [3:0] b,  // 4-bit input B
    input  wire [3:0] c,  // 4-bit input C
    input  wire [3:0] d,  // 4-bit input D
    output wire [3:0] y   // 4-bit output Y
);
    // Intermediate signals
    wire [3:0] ab_and;
    wire [3:0] cd_and;
    
    // Instantiate first level computation module
    first_level_and first_level_computation (
        .a_in(a),
        .b_in(b),
        .c_in(c),
        .d_in(d),
        .ab_out(ab_and),
        .cd_out(cd_and)
    );
    
    // Instantiate result computation module
    result_computation final_stage (
        .ab_in(ab_and),
        .cd_in(cd_and),
        .result_out(y)
    );
endmodule

// First level computation module - handles first stage AND operations
module first_level_and #(
    parameter BIT_WIDTH = 4
)(
    input  wire [BIT_WIDTH-1:0] a_in,    // Input vector A
    input  wire [BIT_WIDTH-1:0] b_in,    // Input vector B
    input  wire [BIT_WIDTH-1:0] c_in,    // Input vector C
    input  wire [BIT_WIDTH-1:0] d_in,    // Input vector D
    output wire [BIT_WIDTH-1:0] ab_out,  // A AND B result
    output wire [BIT_WIDTH-1:0] cd_out   // C AND D result
);
    // Bitwise operations submodules
    bitwise_and #(.WIDTH(BIT_WIDTH)) ab_operation (
        .operand1(a_in),
        .operand2(b_in),
        .result(ab_out)
    );
    
    bitwise_and #(.WIDTH(BIT_WIDTH)) cd_operation (
        .operand1(c_in),
        .operand2(d_in),
        .result(cd_out)
    );
endmodule

// Result computation module - processes second stage AND operation
module result_computation #(
    parameter BIT_WIDTH = 4
)(
    input  wire [BIT_WIDTH-1:0] ab_in,     // AB intermediate result
    input  wire [BIT_WIDTH-1:0] cd_in,     // CD intermediate result
    output wire [BIT_WIDTH-1:0] result_out // Final result
);
    // Final AND operation
    bitwise_and #(.WIDTH(BIT_WIDTH)) final_operation (
        .operand1(ab_in),
        .operand2(cd_in),
        .result(result_out)
    );
endmodule

// Optimized basic bitwise AND operation module
module bitwise_and #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] operand1,  // First operand
    input  wire [WIDTH-1:0] operand2,  // Second operand
    output wire [WIDTH-1:0] result     // Operation result
);
    // Perform bitwise AND with improved datapath
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : and_bit
            // Individual bit AND operations for better timing control
            and (result[i], operand1[i], operand2[i]);
        end
    endgenerate
endmodule