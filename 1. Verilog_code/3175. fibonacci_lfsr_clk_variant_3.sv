//SystemVerilog
module fibonacci_lfsr_clk(
    input clk,
    input rst,
    input req,           // 请求信号 (替代 valid)
    output reg ack,      // 应答信号 (替代 ready)
    output reg lfsr_clk
);
    reg [4:0] lfsr;
    reg feedback_r;      // 流水线寄存器存储反馈值
    wire feedback = lfsr[4] ^ lfsr[2];
    reg req_d;           // 延迟请求信号
    reg req_edge;        // 请求上升沿检测寄存器
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= 5'h1F;     // Non-zero initial value
            lfsr_clk <= 1'b0;
            req_d <= 1'b0;
            ack <= 1'b0;
            feedback_r <= 1'b0;
            req_edge <= 1'b0;
        end else begin
            req_d <= req;      // 捕获请求信号
            
            // 第一级流水线 - 检测上升沿并计算反馈
            if (req && !req_d) begin
                feedback_r <= feedback;  // 缓存反馈值
                req_edge <= 1'b1;        // 标记检测到上升沿
            end else begin
                req_edge <= 1'b0;
            end
            
            // 第二级流水线 - 更新LFSR和输出
            if (req_edge) begin
                lfsr <= {lfsr[3:0], feedback_r};  // 使用缓存的反馈值
                lfsr_clk <= lfsr[4];
                ack <= 1'b1;   // 确认请求
            end else if (!req && req_d) begin
                ack <= 1'b0;   // 复位确认信号
            end
        end
    end
endmodule