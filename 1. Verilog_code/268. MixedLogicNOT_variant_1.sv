//SystemVerilog
module MixedLogicNOT(
    input wire clk,         // 添加时钟信号用于流水线
    input wire rst_n,       // 添加复位信号
    input wire a,           // 输入信号
    output wire y1,         // 组合逻辑输出
    output wire y2          // 流水线寄存输出
);
    // 第一级：组合逻辑实现的NOT门
    wire stage1_not_result;
    assign stage1_not_result = ~a;
    
    // 为高扇出信号增加缓冲寄存器
    reg stage1_buffer1, stage1_buffer2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_buffer1 <= 1'b0;
            stage1_buffer2 <= 1'b0;
        end else begin
            stage1_buffer1 <= stage1_not_result;
            stage1_buffer2 <= stage1_not_result;
        end
    end
    
    // 直接输出组合逻辑结果，使用缓冲器1驱动
    assign y1 = stage1_buffer1;
    
    // 第二级：注册流水线，提高时序性能，使用缓冲器2驱动
    reg stage2_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_reg <= 1'b0;  // 复位值
        end else begin
            stage2_reg <= stage1_buffer2;  // 寄存组合逻辑结果
        end
    end
    
    // 输出寄存后的结果
    assign y2 = stage2_reg;
    
endmodule