module shift_dual_clock #(parameter W=8) (
    input clk_a, clk_b,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
reg [W-1:0] sync_reg;
always @(posedge clk_a) sync_reg <= din;
always @(posedge clk_b) dout <= {sync_reg[6:0], 1'b0};
endmodule