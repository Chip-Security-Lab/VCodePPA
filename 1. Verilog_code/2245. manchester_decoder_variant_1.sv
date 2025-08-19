//SystemVerilog
// 曼彻斯特解码器 - 优化数据流路径结构
module manchester_decoder (
    input  wire clk,          // 系统时钟
    input  wire rst_n,        // 复位信号，低电平有效
    input  wire encoded_in,   // 曼彻斯特编码输入
    output wire decoded_out,  // 解码后的数据输出
    output wire clk_recovered // 恢复的时钟信号输出
);
    // 寄存器定义 - 流水线级
    reg encoded_r1;           // 第一级输入寄存
    reg encoded_r2;           // 第二级输入寄存
    reg prev_bit_r;           // 前一位状态寄存
    
    // 中间信号定义
    wire transition_detected; // 转换检测信号
    
    // 输出寄存器
    reg decoded_r;            // 解码数据寄存器
    reg clk_recovered_r;      // 恢复时钟寄存器
    
    // 信号转换检测 - 组合逻辑路径
    assign transition_detected = encoded_r1 ^ encoded_r2;
    
    // 第一级流水线 - 输入信号采样
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_r1 <= 1'b0;
            encoded_r2 <= 1'b0;
        end else begin
            encoded_r1 <= encoded_in;    // 采样当前输入
            encoded_r2 <= encoded_r1;    // 保存前一个采样
        end
    end
    
    // 第二级流水线 - 前一位状态更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_bit_r <= 1'b0;
        end else begin
            prev_bit_r <= encoded_r1;   // 更新前一位状态
        end
    end
    
    // 第三级流水线 - 数据解码逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_r <= 1'b0;
            clk_recovered_r <= 1'b0;
        end else begin
            decoded_r <= encoded_r1 ^ prev_bit_r;       // 解码数据
            clk_recovered_r <= transition_detected;     // 恢复时钟
        end
    end
    
    // 输出信号分配
    assign decoded_out = decoded_r;
    assign clk_recovered = clk_recovered_r;
    
endmodule