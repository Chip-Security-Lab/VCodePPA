//SystemVerilog
module Masked_XNOR (
    input wire clk,          // 时钟输入用于流水线寄存器
    input wire rst_n,        // 复位信号
    input wire en_mask,      // 掩码使能信号
    input wire [3:0] mask,   // 掩码输入
    input wire [3:0] data,   // 数据输入
    output reg [3:0] res     // 寄存器化输出
);

    // 内部信号定义
    wire [3:0] xor_result;   // 组合逻辑XOR结果
    wire [3:0] masked_result; // 组合逻辑最终结果
    
    reg [3:0] stage1_xor_result; // 第一级流水线-XOR结果
    reg stage1_en_mask;          // 第一级流水线-使能
    reg [3:0] stage1_data;       // 第一级流水线-原始数据
    
    reg [3:0] stage2_result;     // 第二级流水线-最终结果

    // 组合逻辑计算 - 将计算前移
    assign xor_result = data ^ mask;
    assign masked_result = en_mask ? ~xor_result : data;

    // 第一级流水线 - 寄存器移动到组合逻辑之后
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_xor_result <= 4'b0;
            stage1_en_mask <= 1'b0;
            stage1_data <= 4'b0;
        end else begin
            stage1_xor_result <= xor_result;
            stage1_en_mask <= en_mask;
            stage1_data <= data;
        end
    end

    // 第二级流水线 - 前一级的结果与移动寄存器之后的逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 4'b0;
        end else begin
            stage2_result <= stage1_en_mask ? ~stage1_xor_result : stage1_data;
        end
    end

    // 输出级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 4'b0;
        end else begin
            res <= stage2_result;
        end
    end

endmodule