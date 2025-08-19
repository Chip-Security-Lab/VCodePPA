//SystemVerilog
module BaselineTracker #(parameter W=8, TC=8'h10) (
    input clk,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    reg [W-1:0] baseline;
    reg [W-1:0] din_reg;
    reg baseline_gt_din;
    
    always @(posedge clk) begin
        din_reg <= din;
        baseline_gt_din <= din > baseline;
    end
    
    always @(posedge clk) begin
        baseline <= baseline_gt_din ? baseline + TC : baseline - TC;
    end
    
    always @(posedge clk) begin
        dout <= din_reg - baseline;
    end
endmodule