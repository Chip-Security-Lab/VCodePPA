module subtractor_pipelined (
    input wire clk,           // 时钟信号
    input wire rst_n,         // 复位信号，低电平有效
    input wire valid_in,      // 输入数据有效信号
    output reg ready_out,     // 输出就绪信号
    input wire [7:0] a,       // 被减数
    input wire [7:0] b,       // 减数
    output reg [7:0] res,     // 差
    output reg valid_out      // 输出数据有效信号
);

// 流水线寄存器
reg [7:0] a_stage1, b_stage1;
reg valid_stage1;
reg [7:0] diff_stage2;
reg valid_stage2;

// 流水线控制逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ready_out <= 1'b1;
        valid_out <= 1'b0;
        valid_stage1 <= 1'b0;
        valid_stage2 <= 1'b0;
        res <= 8'd0;
    end else begin
        // 默认状态
        ready_out <= 1'b1;
        
        // 第一级流水线：输入寄存
        if (valid_in && ready_out) begin
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= 1'b1;
        end else if (!valid_in) begin
            valid_stage1 <= 1'b0;
        end
        
        // 第二级流水线：减法运算
        if (valid_stage1) begin
            diff_stage2 <= a_stage1 - b_stage1;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
        
        // 输出级：结果输出
        if (valid_stage2) begin
            res <= diff_stage2;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
end

endmodule