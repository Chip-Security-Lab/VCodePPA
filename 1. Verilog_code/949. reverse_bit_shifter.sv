module reverse_bit_shifter (
    input [15:0] din,
    input [3:0] shift,
    output [15:0] dout
);
wire [15:0] reversed_in = {<<{din}};  // 位反转操作
wire [15:0] shifted = reversed_in >> shift;
assign dout = {<<{shifted}};         // 再次反转恢复顺序
endmodule