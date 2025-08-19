module asym_bidir_shifter (
    input [15:0] data,
    input [3:0] l_shift, // 左移量
    input [2:0] r_shift, // 右移量
    output [15:0] result
);
assign result = (data << l_shift) | (data >> r_shift);
endmodule