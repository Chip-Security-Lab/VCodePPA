module subtractor_with_cout (
    input wire clk,              // 时钟信号
    input wire rst_n,            // 异步复位，低电平有效
    input wire [3:0] minuend,    // 被减数
    input wire [3:0] subtrahend, // 减数
    output reg [3:0] difference, // 差
    output reg cout             // 借位输出
);

// 流水线寄存器定义
reg [3:0] minuend_pipe_1;
reg [3:0] subtrahend_pipe_1;
reg [3:0] minuend_pipe_2;
reg [3:0] subtrahend_pipe_2;
reg [4:0] result_pipe;

// 流水线级1：输入采样和符号扩展
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        minuend_pipe_1 <= 4'b0;
        subtrahend_pipe_1 <= 4'b0;
    end else begin
        minuend_pipe_1 <= minuend;
        subtrahend_pipe_1 <= subtrahend;
    end
end

// 流水线级2：数据对齐
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        minuend_pipe_2 <= 4'b0;
        subtrahend_pipe_2 <= 4'b0;
    end else begin
        minuend_pipe_2 <= minuend_pipe_1;
        subtrahend_pipe_2 <= subtrahend_pipe_1;
    end
end

// 流水线级3：减法计算
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result_pipe <= 5'b0;
    end else begin
        result_pipe <= {1'b0, minuend_pipe_2} - {1'b0, subtrahend_pipe_2};
    end
end

// 流水线级4：输出生成
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        difference <= 4'b0;
        cout <= 1'b0;
    end else begin
        {cout, difference} <= result_pipe;
    end
end

endmodule