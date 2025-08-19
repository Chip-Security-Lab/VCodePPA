//SystemVerilog
module AsyncMaskITRC #(parameter IRQ_COUNT=4) (
    input wire [IRQ_COUNT-1:0] interrupt_lines,
    input wire [IRQ_COUNT-1:0] mask_bits,
    output wire [IRQ_COUNT-1:0] masked_interrupts,
    output wire [$clog2(IRQ_COUNT)-1:0] highest_irq,
    output wire irq_active
);
    // Optimized implementation using parallel priority encoding
    wire [IRQ_COUNT-1:0] effective_irq = interrupt_lines & ~mask_bits;
    wire [IRQ_COUNT-1:0] priority_mask;
    
    // Optimized priority mask generation using parallel prefix OR
    genvar j;
    generate
        for (j = 0; j < IRQ_COUNT; j = j + 1) begin : gen_priority
            assign priority_mask[j] = (j == 0) ? effective_irq[j] : 
                                    effective_irq[j] | priority_mask[j-1];
        end
    endgenerate
    
    // Optimized highest priority selection
    wire [IRQ_COUNT-1:0] selected_irq = effective_irq & ~{priority_mask[IRQ_COUNT-2:0], 1'b0};
    
    // Optimized one-hot to binary encoder
    wire [$clog2(IRQ_COUNT)-1:0] encoded_irq;
    generate
        for (j = 0; j < $clog2(IRQ_COUNT); j = j + 1) begin : gen_encoder
            assign encoded_irq[j] = |(selected_irq & (1 << j));
        end
    endgenerate
    
    assign masked_interrupts = effective_irq;
    assign irq_active = |effective_irq;
    assign highest_irq = encoded_irq;
endmodule