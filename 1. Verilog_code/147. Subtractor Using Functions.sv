module subtractor_function (
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output wire [7:0] res // 差
);

function [7:0] subtract;
    input [7:0] x, y;
    subtract = x - y;
endfunction

assign res = subtract(a, b);  // 调用函数实现减法

endmodule