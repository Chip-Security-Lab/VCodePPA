module subtractor_4bit (
    input wire [3:0] a,   // 被减数
    input wire [3:0] b,   // 减数
    output reg [3:0] res  // 差
);

always @(*) begin
    res = a - b;  // 直接使用减法运算符
end

endmodule