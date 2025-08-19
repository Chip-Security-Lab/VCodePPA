module subtractor_with_cout (
    input wire [3:0] minuend,
    input wire [3:0] subtrahend,
    output wire [3:0] difference,
    output wire cout
);

// 优化后的4位减法器实现
wire [3:0] b_not = ~subtrahend;
wire [3:0] diff_temp;
wire [3:0] borrow;

// 第0位
assign diff_temp[0] = minuend[0] ^ b_not[0];
assign borrow[0] = (~minuend[0] & b_not[0]);

// 第1位
assign diff_temp[1] = minuend[1] ^ b_not[1] ^ borrow[0];
assign borrow[1] = (~minuend[1] & b_not[1]) | (borrow[0] & (~minuend[1] | b_not[1]));

// 第2位
assign diff_temp[2] = minuend[2] ^ b_not[2] ^ borrow[1];
assign borrow[2] = (~minuend[2] & b_not[2]) | (borrow[1] & (~minuend[2] | b_not[2]));

// 第3位
assign diff_temp[3] = minuend[3] ^ b_not[3] ^ borrow[2];
assign borrow[3] = (~minuend[3] & b_not[3]) | (borrow[2] & (~minuend[3] | b_not[3]));

assign difference = diff_temp;
assign cout = borrow[3];

endmodule