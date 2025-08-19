//SystemVerilog
module level_async_ismu #(parameter WIDTH = 8)(
    input [WIDTH-1:0] irq_in,
    input [WIDTH-1:0] mask,
    input clear_n,
    output [WIDTH-1:0] active_irq,
    output irq_present
);
    // 直接通过位运算实现中断屏蔽
    // 使用位与操作简化了补码计算逻辑
    wire [WIDTH-1:0] masked_irq;
    
    // 简化的掩码应用方式
    assign masked_irq = irq_in & (~mask);
    
    // 应用clear_n使能信号
    assign active_irq = masked_irq & {WIDTH{clear_n}};
    
    // 简化的中断存在逻辑判断
    assign irq_present = |active_irq;
endmodule