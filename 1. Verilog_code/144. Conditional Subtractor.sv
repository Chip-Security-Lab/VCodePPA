module subtractor_conditional (
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output reg [7:0] res  // 差
);

always @(*) begin
    if (a >= b) begin
        res = a - b;  // 正常减法
    end else begin
        res = 0;      // 可自定义处理方式
    end
end

endmodule