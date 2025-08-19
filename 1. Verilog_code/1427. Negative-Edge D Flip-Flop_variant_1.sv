//SystemVerilog
module neg_edge_d_ff (
    input  wire clk,     // 系统时钟
    input  wire d_in,    // 数据输入
    output reg  q_out    // 数据输出
);
    // 数据流分段 - 第一级处理
    wire data_stage1;
    assign data_stage1 = d_in; // 输入缓冲
    
    // 数据流分段 - 中间处理
    reg data_stage2;
    always @(posedge clk) begin
        data_stage2 <= data_stage1; // 添加流水线寄存器，在上升沿捕获
    end
    
    // 最终输出寄存器 - 使用下降沿
    always @(negedge clk) begin
        q_out <= data_stage2; // 最终输出处理
    end
endmodule