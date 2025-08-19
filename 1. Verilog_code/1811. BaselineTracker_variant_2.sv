//SystemVerilog
module BaselineTracker #(parameter W=8, TC=8'h10) (
    input clk,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    reg [W-1:0] baseline;
    reg [W-1:0] din_reg;
    
    always @(posedge clk) begin
        din_reg <= din;
        
        if (din > baseline) begin
            baseline <= baseline + TC;
        end else begin
            baseline <= baseline - TC;
        end
        
        dout <= din_reg - baseline;
    end
endmodule