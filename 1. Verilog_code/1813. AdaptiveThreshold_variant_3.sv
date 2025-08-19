//SystemVerilog
module AdaptiveThreshold #(parameter W=8) (
    input clk,
    input [W-1:0] signal,
    output reg threshold
);
    reg [W+3:0] sum;
    reg [W-1:0] signal_reg;
    reg [W+3:0] sum_shifted;
    
    always @(posedge clk) begin
        signal_reg <= signal;
        sum_shifted <= sum[W+3:W];
        sum <= sum + signal_reg - sum_shifted;
        threshold <= sum_shifted >> 2;
    end
endmodule