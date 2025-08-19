module BaselineTracker #(parameter W=8, TC=8'h10) (
    input clk,
    input [W-1:0] din,
    output [W-1:0] dout
);
    reg [W-1:0] baseline;
    always @(posedge clk) begin
        baseline <= (din > baseline) ? baseline + TC : baseline - TC;
    end
    assign dout = din - baseline;
endmodule
