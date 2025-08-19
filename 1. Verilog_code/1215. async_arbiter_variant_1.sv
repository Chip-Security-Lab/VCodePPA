//SystemVerilog
module async_arbiter #(parameter WIDTH=8) (
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
    // 直接使用组合逻辑计算优先级仲裁结果
    // 表达式 req_i & (~req_i + 1) 等价于 req_i & (-req_i)
    // 这是一种常见的仅保留最低有效位的技巧
    assign grant_o = req_i & (-req_i);
endmodule