module AdaptiveThreshold #(parameter W=8) (
    input clk,
    input [W-1:0] signal,
    output reg threshold
);
    reg [W+3:0] sum;
    always @(posedge clk) begin
        sum <= sum + signal - sum[W+3:W];
        threshold <= sum[W+3:W] >> 2;
    end
endmodule