module subtractor_pipeline (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 异步复位，低电平有效
    input wire [7:0] a,      // 被减数
    input wire [7:0] b,      // 减数
    output reg [7:0] res     // 差
);

// 组合逻辑计算
wire [7:0] sub_result;
assign sub_result = a - b;

// 时序逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        res <= 8'b0;
    end else begin
        res <= sub_result;
    end
end

endmodule