//SystemVerilog
// SystemVerilog
// Module: conditional_inversion_subtractor_4bit
// Description: Top level module for a 4-bit subtractor using conditional inversion.
// This module is a placeholder to demonstrate replacing a different operation (like NOT)
// with a subtractor using conditional inversion.
// Note: The original code was a NOT gate. This transformation replaces it with a subtractor.
// The input 'A' is now treated as the minuend, and a fixed subtrahend (e.g., 0) is assumed
// or the operation is simplified to just demonstrate the conditional inversion concept
// within a subtractor context, which for a single input doesn't directly map to a standard subtractor.
// A standard subtractor needs two inputs (minuend and subtrahend).
// To fit the single input 'A' structure, we'll demonstrate the conditional inversion
// logic as if it were part of a subtraction where one operand is 'A'.
// A more realistic subtractor would have inputs A and B and output A-B.
// Given the constraint to use the original module's interface (single input A),
// we'll implement a simplified operation that uses conditional inversion,
// for example, calculating 0 - A using 2's complement.
// 0 - A = 0 + (-A) = 0 + (~A + 1) = ~A + 1.
// This essentially calculates the 2's complement of A.

module conditional_inversion_subtractor_4bit (
    input wire clk,
    input wire [3:0] A,
    output wire [3:0] Y
);

    // Internal wire to connect the submodule output to the top level output
    wire [3:0] y_internal;

    // Instantiate the core subtractor logic with negative edge clocking
    conditional_inversion_subtractor_core_neg_edge #(
        .DATA_WIDTH(4) // Parameterize the data width
    ) core_logic_inst (
        .clk(clk),     // Clock input
        .A(A),         // Input data (minuend)
        .Y(y_internal) // Output data (result of 0 - A)
    );

    // Assign the internal output to the top level output
    assign Y = y_internal;

endmodule

// Module: conditional_inversion_subtractor_core_neg_edge
// Description: Core logic for a parameterized subtractor using conditional inversion
// to calculate 0 - A (2's complement of A) on the negative clock edge.
module conditional_inversion_subtractor_core_neg_edge #(
    parameter DATA_WIDTH = 4 // Parameter for data width
) (
    input wire clk,
    input wire [DATA_WIDTH-1:0] A,
    output reg [DATA_WIDTH-1:0] Y
);

    // Internal signals for conditional inversion logic
    wire [DATA_WIDTH-1:0] inverted_A;
    wire [DATA_WIDTH-1:0] result_add_one;

    // Conditional inversion: For calculating 0 - A, we always invert A.
    // In a general subtractor (A - B), we would invert B based on the operation sign.
    // Here, we are effectively calculating 0 - A, so we invert A.
    assign inverted_A = ~A;

    // Add 1 to the inverted value to complete the 2's complement (0 - A = ~A + 1)
    assign result_add_one = inverted_A + 1;

    // Register the result on the negative edge of the clock
    always @ (negedge clk) begin
        Y <= result_add_one;
    end

endmodule