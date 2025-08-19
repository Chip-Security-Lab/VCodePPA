module subtractor_twos_complement (
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output reg [7:0] res  // 差
);

// 内部信号
wire [7:0] b_comp;        // b的二进制补码
wire [7:0] sum;           // 加法结果
wire overflow;            // 溢出标志

// 计算b的二进制补码 (取反加1)
assign b_comp = ~b + 1'b1;

// 执行加法 (a + (-b))
assign sum = a + b_comp;

// 检测溢出
assign overflow = (a[7] == b[7]) && (sum[7] != a[7]);

// 输出结果
always @(*) begin
    if (overflow) begin
        res = 8'b0;  // 溢出时返回0，与原代码行为一致
    end else begin
        res = sum;
    end
end

endmodule