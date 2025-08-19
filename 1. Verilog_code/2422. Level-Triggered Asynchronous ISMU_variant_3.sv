//SystemVerilog
module level_async_ismu #(parameter WIDTH = 8)(
    input [WIDTH-1:0] irq_in,
    input [WIDTH-1:0] mask,
    input clear_n,
    output [WIDTH-1:0] active_irq,
    output irq_present
);
    wire [WIDTH-1:0] masked_irq;
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] sub_result;
    
    // 借位减法器实现
    // 第一个位的借位初始化为0
    assign borrow[0] = 0;
    
    // 实现借位减法: irq_in - mask
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_subtractor
            if (i < WIDTH-1) begin
                // 计算下一位的借位
                assign borrow[i+1] = (~irq_in[i] & mask[i]) | 
                                    (borrow[i] & ~(irq_in[i] ^ mask[i]));
            end
            // 计算当前位的减法结果
            assign sub_result[i] = irq_in[i] ^ mask[i] ^ borrow[i];
        end
    endgenerate
    
    // 应用清除信号
    assign masked_irq = sub_result & {WIDTH{clear_n}};
    
    // 输出赋值
    assign active_irq = masked_irq;
    
    // 检测是否有中断存在
    assign irq_present = |masked_irq;
endmodule