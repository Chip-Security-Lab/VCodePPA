//SystemVerilog
module shift_saturation #(parameter W=8) (
    input clk,
    input signed [W-1:0] din,
    input [2:0] shift,
    output reg signed [W-1:0] dout
);
always @(posedge clk) begin
    dout <= (shift >= W) ? {W{1'b0}} : (din >>> shift);
end
endmodule