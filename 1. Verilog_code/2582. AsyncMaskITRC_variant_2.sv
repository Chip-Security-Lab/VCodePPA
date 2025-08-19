//SystemVerilog
module AsyncMaskITRC #(parameter IRQ_COUNT=4) (
    input wire [IRQ_COUNT-1:0] interrupt_lines,
    input wire [IRQ_COUNT-1:0] mask_bits,
    output wire [IRQ_COUNT-1:0] masked_interrupts,
    output wire [$clog2(IRQ_COUNT)-1:0] highest_irq,
    output wire irq_active
);

    // 计算有效中断信号
    wire [IRQ_COUNT-1:0] mask_pattern;
    wire [IRQ_COUNT-1:0] effective_irq;

    assign mask_pattern = interrupt_lines ^ mask_bits;
    assign effective_irq = interrupt_lines & mask_pattern;
    assign masked_interrupts = effective_irq;
    assign irq_active = |effective_irq;

endmodule

// 优先级编码器模块
module PriorityEncoder #(parameter IRQ_COUNT=4) (
    input wire [IRQ_COUNT-1:0] effective_irq,
    output reg [$clog2(IRQ_COUNT)-1:0] priority_id
);

    always @(*) begin
        priority_id = {$clog2(IRQ_COUNT){1'b0}}; // 初始化为全0
        casez (effective_irq)
            {1'b1, {IRQ_COUNT-1{1'b?}}}: priority_id = IRQ_COUNT - 1;
            {{1'b0, 1'b1}, {IRQ_COUNT-2{1'b?}}}: priority_id = IRQ_COUNT - 2;
            default: begin
                // 处理剩余位，使用优化的逻辑而不是循环
                integer i;
                for (i = IRQ_COUNT-3; i >= 0; i=i-1) begin
                    if (effective_irq[i]) 
                        priority_id = i[$clog2(IRQ_COUNT)-1:0];
                end
            end
        endcase
    end

endmodule

// 顶层模块实例化
module TopModule #(parameter IRQ_COUNT=4) (
    input wire [IRQ_COUNT-1:0] interrupt_lines,
    input wire [IRQ_COUNT-1:0] mask_bits,
    output wire [IRQ_COUNT-1:0] masked_interrupts,
    output wire [$clog2(IRQ_COUNT)-1:0] highest_irq,
    output wire irq_active
);

    wire [IRQ_COUNT-1:0] effective_irq;

    AsyncMaskITRC #(IRQ_COUNT) mask_inst (
        .interrupt_lines(interrupt_lines),
        .mask_bits(mask_bits),
        .masked_interrupts(masked_interrupts),
        .irq_active(irq_active)
    );

    PriorityEncoder #(IRQ_COUNT) encoder_inst (
        .effective_irq(effective_irq),
        .priority_id(highest_irq)
    );

endmodule