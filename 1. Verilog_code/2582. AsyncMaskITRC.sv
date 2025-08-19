module AsyncMaskITRC #(parameter IRQ_COUNT=4) (
    input wire [IRQ_COUNT-1:0] interrupt_lines,
    input wire [IRQ_COUNT-1:0] mask_bits,
    output wire [IRQ_COUNT-1:0] masked_interrupts,
    output wire [$clog2(IRQ_COUNT)-1:0] highest_irq,
    output wire irq_active
);
    wire [IRQ_COUNT-1:0] effective_irq = interrupt_lines & ~mask_bits;
    assign masked_interrupts = effective_irq;
    assign irq_active = |effective_irq;
    
    // Priority encoder for highest interrupt
    reg [$clog2(IRQ_COUNT)-1:0] priority_id;
    integer i;
    always @(*) begin
        priority_id = 0;
        for (i = IRQ_COUNT-1; i >= 0; i=i-1)
            if (effective_irq[i]) priority_id = i[$clog2(IRQ_COUNT)-1:0];
    end
    assign highest_irq = priority_id;
endmodule