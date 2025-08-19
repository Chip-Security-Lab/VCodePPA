//SystemVerilog
module shift_saturation #(parameter W=8) (
    input clk,
    input signed [W-1:0] din,
    input [2:0] shift,
    output reg signed [W-1:0] dout
);

reg signed [W-1:0] din_reg;
reg [2:0] shift_reg;

always @(posedge clk) begin
    din_reg <= din;
    shift_reg <= shift;
end

always @(posedge clk) begin
    dout <= (shift_reg >= W) ? {W{1'b0}} : (din_reg >>> shift_reg);
end

endmodule