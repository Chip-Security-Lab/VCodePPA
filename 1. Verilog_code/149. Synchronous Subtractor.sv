module subtractor_sync (
    input wire clk,       // 时钟信号
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output reg [7:0] res  // 差
);

always @(posedge clk) begin
    res <= a - b;  // 时钟同步方式更新结果
end

endmodule