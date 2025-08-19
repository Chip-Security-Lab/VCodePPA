//SystemVerilog
module Adder_10 (
    input clk,       // Clock input for synchronous operations
    input rst_n,     // Asynchronous active-low reset
    input [3:0] A,   // First input operand
    input [3:0] B,   // Second input operand
    output [4:0] sum // Pipelined sum output
);

    // Internal wire for Stage 1 combinatorial output (Addition)
    wire [4:0] stage1_sum_comb;

    // Internal registers for pipeline stages
    // Stage 2 register: holds result from Stage 1
    reg [4:0] stage2_sum_reg;
    // Stage 3 register: holds result from Stage 2 (final output stage)
    reg [4:0] stage3_sum_reg;

    // Stage 1: Combinatorial Logic - Perform the addition
    // This stage computes the sum of A and B combinatorially.
    // The critical path is the addition logic itself.
    assign stage1_sum_comb = A + B;

    // Stage 2: Sequential Logic - Register the result from Stage 1
    // This stage registers the output of Stage 1 on the positive clock edge.
    // An asynchronous reset is included.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset the register to a known state (e.g., zero)
            stage2_sum_reg <= 5'b0;
        end else begin
            // On the clock edge, capture the result from the previous stage
            stage2_sum_reg <= stage1_sum_comb;
        end
    end

    // Stage 3: Sequential Logic - Register the result from Stage 2
    // This stage registers the output of Stage 2 on the positive clock edge.
    // This is the final pipeline stage before the output.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset the register to a known state (e.g., zero)
            stage3_sum_reg <= 5'b0;
        end else begin
            // On the clock edge, capture the result from the previous stage
            stage3_sum_reg <= stage2_sum_reg;
        end
    end

    // Output Assignment: Connect the final registered result to the output port
    // The output 'sum' is the result of A + B from two clock cycles ago.
    assign sum = stage3_sum_reg;

endmodule