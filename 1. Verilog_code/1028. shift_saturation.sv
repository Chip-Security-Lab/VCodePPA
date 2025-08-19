module shift_saturation #(parameter W=8) (
    input clk,
    input signed [W-1:0] din,
    input [2:0] shift,
    output reg signed [W-1:0] dout
);
always @(posedge clk) begin
    if (shift >= W) dout <= {W{1'b0}};
    else dout <= din >>> shift;
end
endmodule