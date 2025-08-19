module subtractor_complement (
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output reg [7:0] res  // 差
);

always @(*) begin
    res = a + (~b + 1);  // 使用补码转换实现减法
end

endmodule