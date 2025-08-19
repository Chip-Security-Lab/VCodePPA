//SystemVerilog
// 优化的AND门设计，采用增加流水线深度后的结构提高最大工作频率
module and_gate_optimized (
    input  wire clk,       // 时钟输入
    input  wire rst_n,     // 异步复位（低有效）
    input  wire a,         // 数据输入A
    input  wire b,         // 数据输入B
    output wire y          // 数据输出Y
);
    // 内部信号定义 - 用于增加的流水线级
    reg a_stage1, b_stage1;            // 第一级输入寄存器
    reg a_stage2, b_stage2;            // 第二级输入缓冲寄存器
    reg partial_and_stage3;            // 第三级部分与运算结果
    reg result_stage4;                 // 第四级最终结果
    
    // 第一级流水线 - 初始输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end
    
    // 第二级流水线 - 输入缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= 1'b0;
            b_stage2 <= 1'b0;
        end else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
        end
    end
    
    // 第三级流水线 - 逻辑运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_and_stage3 <= 1'b0;
        end else begin
            partial_and_stage3 <= a_stage2 & b_stage2;  // 核心AND运算
        end
    end
    
    // 第四级流水线 - 结果寄存与缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage4 <= 1'b0;
        end else begin
            result_stage4 <= partial_and_stage3;
        end
    end
    
    // 输出赋值
    assign y = result_stage4;

endmodule