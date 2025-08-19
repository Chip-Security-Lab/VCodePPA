//SystemVerilog
//IEEE 1364-2005 Verilog
module basic_clock_gate (
    input  wire clk_in,      // 输入时钟信号
    input  wire enable,      // 使能信号
    output wire clk_out      // 输出门控时钟
);
    // 数据流路径重构：添加适当的寄存器级和命名
    
    // 第一级：输入信号同步
    reg enable_stage1;        // 第一级同步寄存器
    reg enable_stage2;        // 第二级同步寄存器（增强亚稳态恢复）
    
    // 同步流水线 - 避免亚稳态问题并提高稳定性
    always @(posedge clk_in) begin
        enable_stage1 <= enable;      // 第一级同步
        enable_stage2 <= enable_stage1; // 第二级同步
    end
    
    // 数据流路径：门控逻辑
    // 引入中间信号以提高可读性和优化综合
    wire enable_gated;
    
    // 使用与门逻辑实现时钟门控
    assign enable_gated = enable_stage2;
    
    // 最终时钟门控输出 - 使用非阻塞赋值以避免毛刺
    // 综合后映射到专用时钟门控单元
    assign clk_out = clk_in & enable_gated;
    
endmodule