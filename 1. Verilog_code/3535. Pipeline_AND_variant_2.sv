//SystemVerilog
// Top-level module with pipelined subtraction operation
module Pipeline_AND (
    input           clk,
    input  [15:0]   din_a, 
    input  [15:0]   din_b,
    output [15:0]   dout
);
    // Configuration parameters
    localparam DATA_WIDTH = 16;
    
    // Internal signals
    wire [DATA_WIDTH-1:0] sub_result;
    
    // Computational logic unit
    Computational_Unit #(
        .WIDTH(DATA_WIDTH)
    ) u_computational_unit (
        .operand_a  (din_a),
        .operand_b  (din_b),
        .result     (sub_result)
    );
    
    // Data pipeline stage
    Pipeline_Stage #(
        .WIDTH(DATA_WIDTH)
    ) u_pipeline_stage (
        .clk        (clk),
        .data_in    (sub_result),
        .data_out   (dout)
    );
    
endmodule

// Computational logic unit module (containing different possible operations)
module Computational_Unit #(
    parameter WIDTH = 16
) (
    input  [WIDTH-1:0] operand_a,
    input  [WIDTH-1:0] operand_b,
    output [WIDTH-1:0] result
);
    // Implementation of specific computational operation
    Subtractor_Operation #(
        .WIDTH(WIDTH)
    ) u_subtractor_operation (
        .in_a    (operand_a),
        .in_b    (operand_b),
        .out     (result)
    );
    
endmodule

// Subtractor operation module (implementing subtraction using 2's complement addition)
module Subtractor_Operation #(
    parameter WIDTH = 16
) (
    input  [WIDTH-1:0] in_a,
    input  [WIDTH-1:0] in_b,
    output [WIDTH-1:0] out
);
    // Internal signals for 2's complement implementation
    wire [WIDTH-1:0] inverted_b;
    wire [WIDTH-1:0] ones_complement;
    wire [WIDTH-1:0] twos_complement;
    
    // Create 2's complement of in_b
    assign ones_complement = ~in_b;
    assign twos_complement = ones_complement + 1'b1;
    
    // Subtraction using 2's complement addition: A - B = A + (-B)
    assign out = in_a + twos_complement;
    
endmodule

// Pipeline stage module with configurable width
module Pipeline_Stage #(
    parameter WIDTH = 16
) (
    input                  clk,
    input      [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Register implementation module
    Register_Block #(
        .WIDTH(WIDTH)
    ) u_register_block (
        .clk      (clk),
        .data_in  (data_in),
        .data_out (data_out)
    );
    
endmodule

// Register block module for data storage
module Register_Block #(
    parameter WIDTH = 16
) (
    input                  clk,
    input      [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Sequential logic for the pipeline register
    always @(posedge clk) begin
        data_out <= data_in;
    end
    
endmodule