module subtractor_with_cout (
    input wire [3:0] minuend,
    input wire [3:0] subtrahend,
    output wire [3:0] difference,
    output wire cout
);

wire [3:0] subtrahend_comp;  // 减数的补码
wire [4:0] sum_result;       // 5位加法结果

// 计算减数的补码
assign subtrahend_comp = ~subtrahend + 1'b1;

// 使用补码加法实现减法
assign sum_result = {1'b0, minuend} + {1'b0, subtrahend_comp};

// 输出结果
assign difference = sum_result[3:0];
assign cout = sum_result[4];

endmodule