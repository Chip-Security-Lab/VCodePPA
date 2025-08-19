module subtractor_multi_input (
    input wire [3:0] a,   // 被减数 1
    input wire [3:0] b,   // 被减数 2
    input wire [3:0] c,   // 被减数 3
    input wire [3:0] d,   // 减数
    output reg [3:0] res  // 差
);

always @(*) begin
    res = a + b + c - d;  // 多输入加减运算
end

endmodule