//SystemVerilog
module pl_reg_bound #(
    parameter W = 8,             // 数据位宽
    parameter MAX = 8'h7F        // 最大值限制
) (
    input  wire        clk,      // 时钟信号
    input  wire        load,     // 加载使能
    input  wire [W-1:0] d_in,    // 输入数据
    output wire [W-1:0] q        // 输出数据
);
    // 流水线阶段信号定义
    wire [W-1:0] stage1_bounded_data;  // 第一阶段：边界检查后的数据
    reg  [W-1:0] stage2_reg_data;      // 第二阶段：寄存器中的数据
    
    // === 第一阶段：数据边界检查 ===
    // 实现边界检查逻辑
    assign stage1_bounded_data = (d_in > MAX) ? MAX : d_in;
    
    // === 第二阶段：数据寄存 ===
    // 数据寄存逻辑，使用单个always块进行控制
    always @(posedge clk)
        if (load) stage2_reg_data <= stage1_bounded_data;
    
    // 输出赋值
    assign q = stage2_reg_data;
    
endmodule