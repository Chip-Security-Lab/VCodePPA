module pipelined_adder(
    input clk,
    input [7:0] a,b,
    output reg [7:0] sum
);
    reg [3:0] a_low,b_low,a_high,b_high;
    reg [3:0] sum_low;
    reg carry;
    
    always @(posedge clk) begin
        // Stage 1: Compute lower 4 bits
        {carry, sum_low} <= a[3:0] + b[3:0];
        a_high <= a[7:4];
        b_high <= b[7:4];
    end
    
    always @(posedge clk) begin
        // Stage 2: Compute upper 4 bits
        sum[7:4] <= a_high + b_high + carry;
        sum[3:0] <= sum_low;
    end
endmodule