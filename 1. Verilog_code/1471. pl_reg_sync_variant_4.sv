//SystemVerilog
module pl_reg_sync #(
    parameter W = 8
)(
    input  wire         clk,    // Clock input
    input  wire         rst_n,  // Active-low asynchronous reset
    input  wire         en,     // Register enable signal
    input  wire [W-1:0] data_in,  // Input data
    output reg  [W-1:0] data_out  // Output data
);

    // Optimized implementation with clear signal hierarchy
    // Asynchronous reset, synchronous enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Use parameter-based initialization for better portability
            data_out <= {W{1'b0}};
        end 
        else if (en) begin
            // Only update when enabled to reduce switching activity
            data_out <= data_in;
        end
        // Implicit else: hold current value (no assignment needed)
    end

endmodule