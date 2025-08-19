//SystemVerilog
module BinSearchDiv(
    input [7:0] D, d,
    output [7:0] Q
);
    reg [7:0] result;
    wire [7:0] sum, carry;
    wire [7:0] candidates[0:7];
    wire [7:0] comparison_results;

    // Han-Carlson adder implementation
    assign sum = candidates[6] + 8'd1; // Sum for the final candidate
    assign carry = (candidates[6] + 8'd1) < candidates[6]; // Carry detection

    always @(*) begin
        // Base case handling
        if (d == 0) begin
            result = 8'hFF; // Maximum value for division by zero
        end else if (d > D) begin
            result = 8'h00; // Result is zero if divisor > dividend
        end else if (d == D) begin
            result = 8'h01; // Result is one if divisor == dividend
        end else begin
            // Binary search optimization using parallel comparison
            result = comparison_results;
        end
    end
    
    // Generate candidate values for comparison
    assign candidates[0] = 8'd64;  // 2^6
    assign candidates[1] = candidates[0] + ((comparison_results[0]) ? 8'd32 : -8'd32);  // ±2^5
    assign candidates[2] = candidates[1] + ((comparison_results[1]) ? 8'd16 : -8'd16);  // ±2^4
    assign candidates[3] = candidates[2] + ((comparison_results[2]) ? 8'd8  : -8'd8);   // ±2^3
    assign candidates[4] = candidates[3] + ((comparison_results[3]) ? 8'd4  : -8'd4);   // ±2^2
    assign candidates[5] = candidates[4] + ((comparison_results[4]) ? 8'd2  : -8'd2);   // ±2^1
    assign candidates[6] = candidates[5] + ((comparison_results[5]) ? 8'd1  : -8'd1);   // ±2^0
    
    // Perform parallel comparisons
    assign comparison_results[0] = (candidates[0] * d <= D) ? 1'b1 : 1'b0;
    assign comparison_results[1] = (candidates[1] * d <= D) ? 1'b1 : 1'b0;
    assign comparison_results[2] = (candidates[2] * d <= D) ? 1'b1 : 1'b0;
    assign comparison_results[3] = (candidates[3] * d <= D) ? 1'b1 : 1'b0;
    assign comparison_results[4] = (candidates[4] * d <= D) ? 1'b1 : 1'b0;
    assign comparison_results[5] = (candidates[5] * d <= D) ? 1'b1 : 1'b0;
    assign comparison_results[6] = (candidates[6] * d <= D) ? 1'b1 : 1'b0;
    
    // Final calculation based on the last comparison
    assign comparison_results[7:7] = (comparison_results[6]) ? sum : candidates[6];
    
    assign Q = result;
endmodule