module saturating_shifter (
    input [7:0] din,
    input [2:0] shift,
    output reg [7:0] dout
);
always @* begin
    if (shift > 3'd5) dout = 8'hFF;  // 最大移位限制
    else dout = din << shift;
end
endmodule