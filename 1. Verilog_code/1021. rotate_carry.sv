module rotate_carry #(parameter W=8) (
    input clk, dir,
    input [W-1:0] din,
    output reg [W-1:0] dout,
    output carry
);
reg carry_bit;
always @(posedge clk) begin
    if(dir) {carry_bit, dout} <= {din, din[W-1]};
    else {dout, carry_bit} <= {din[0], din};
end
assign carry = carry_bit;
endmodule