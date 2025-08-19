module ovf_check_shifter (
    input [7:0] din,
    input [2:0] shift,
    output [7:0] dout,
    output reg ovf
);
assign dout = din << shift;
always @* begin
    ovf = |(din & (8'hFF << (8 - shift))); // 检测移出位是否非零
end
endmodule