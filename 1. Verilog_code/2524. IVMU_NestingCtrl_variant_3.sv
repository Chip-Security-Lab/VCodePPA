//SystemVerilog
// Top module: Instantiates the combinational and sequential submodules
// and connects them to implement the nesting level tracking logic.
module IVMU_NestingCtrl #(parameter LVL=8) ( // Changed default LVL to 8 as requested width
    input clk,                      // Clock signal
    input rst,                      // Asynchronous reset signal
    input [LVL-1:0] int_lvl,        // Input nesting level from interrupt or other source
    output [LVL-1:0] current_lvl    // Output: The current effective nesting level
);

    // Internal wire to connect the output of the combinational logic
    // to the input of the sequential logic.
    wire [LVL-1:0] next_current_lvl;

    // Instantiate the combinational logic submodule.
    // This module calculates the desired next state based on current inputs and state.
    IVMU_NestingCtrl_Combinational #(
        .LVL (LVL) // Pass the parameter LVL to the submodule
    ) u_comb (
        .int_lvl         (int_lvl),       // Connect top-level input int_lvl
        .current_lvl     (current_lvl),   // Connect feedback of the current level from the register
        .next_current_lvl(next_current_lvl) // Connect to the input of the sequential module
    );

    // Instantiate the sequential logic submodule.
    // This module registers the calculated next state on the clock edge.
    IVMU_NestingCtrl_Sequential #(
        .LVL (LVL) // Pass the parameter LVL to the submodule
    ) u_seq (
        .clk             (clk),           // Connect clock
        .rst             (rst),           // Connect reset
        .next_current_lvl(next_current_lvl), // Connect from the output of the combinational module
        .current_lvl     (current_lvl)    // Connect to the top-level output current_lvl
    );

endmodule

// Submodule for combinational logic to determine the next nesting level
module IVMU_NestingCtrl_Combinational #(parameter LVL=8) ( // Changed default LVL to 8
    input [LVL-1:0] int_lvl,        // Input nesting level
    input [LVL-1:0] current_lvl,    // Current registered level
    output [LVL-1:0] next_current_lvl // Calculated next level based on inputs
);

    // Calculate the value that current_lvl should take on the next clock edge,
    // based on the input level and the current level.
    // If int_lvl is non-zero, the next level is the maximum of int_lvl and current_lvl.
    // If int_lvl is zero, the next level resets to 0.

    // Original logic: (int_lvl > current_lvl) ? int_lvl : current_lvl
    // Replaced comparison (int_lvl > current_lvl) with two's complement subtraction logic.
    // For unsigned numbers A and B, A > B is equivalent to the carry-out of A + (~B) + 1 being 1.

    // Calculate A + (~B) + 1 where A = int_lvl, B = current_lvl
    wire [LVL-1:0] current_lvl_inverted = ~current_lvl;
    // Perform the addition int_lvl + (~current_lvl) + 1.
    // Need LVL+1 bits for the sum to capture the carry out.
    wire [LVL:0]   subtraction_sum = {1'b0, int_lvl} + {1'b0, current_lvl_inverted} + 1;

    // The carry out of the LVL-bit subtraction is the MSB of the (LVL+1)-bit sum.
    // This carry out indicates if int_lvl > current_lvl (unsigned).
    wire           int_lvl_is_greater_than_current_lvl = subtraction_sum[LVL];

    assign next_current_lvl = (|int_lvl) ?
                              (int_lvl_is_greater_than_current_lvl ? int_lvl : current_lvl) :
                              {LVL{1'b0}}; // Explicitly size 0

endmodule

// Submodule for sequential logic (register) to hold the current nesting level
module IVMU_NestingCtrl_Sequential #(parameter LVL=8) ( // Changed default LVL to 8
    input clk,                      // Clock signal
    input rst,                      // Asynchronous reset signal
    input [LVL-1:0] next_current_lvl, // Value to be registered
    output reg [LVL-1:0] current_lvl  // Registered output: the current effective nesting level
);

    // Register the calculated next level on the positive clock edge.
    // Apply asynchronous reset to 0.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_lvl <= {LVL{1'b0}}; // Reset current_lvl to 0
        end else begin
            current_lvl <= next_current_lvl; // Update current_lvl with the calculated next value
        end
    end

endmodule