//SystemVerilog
module AsyncMaskITRC #(parameter IRQ_COUNT=4) (
    input wire [IRQ_COUNT-1:0] interrupt_lines,
    input wire [IRQ_COUNT-1:0] mask_bits,
    output wire [IRQ_COUNT-1:0] masked_interrupts,
    output wire [$clog2(IRQ_COUNT)-1:0] highest_irq,
    output wire irq_active
);

    // Stage 1: Direct Masking
    wire [IRQ_COUNT-1:0] masked_input;
    assign masked_input = interrupt_lines & mask_bits;

    // Stage 2: Priority Encoding with Parallel Processing
    wire [IRQ_COUNT-1:0] priority_tree [0:$clog2(IRQ_COUNT)];
    assign priority_tree[0] = masked_input;
    
    genvar i;
    generate
        for (i = 0; i < $clog2(IRQ_COUNT); i = i + 1) begin : PRIORITY_STAGE
            assign priority_tree[i+1] = priority_tree[i] | (priority_tree[i] >> (1 << i));
        end
    endgenerate

    // Output Processing
    wire [IRQ_COUNT-1:0] highest_priority;
    assign highest_priority = priority_tree[$clog2(IRQ_COUNT)] & ~(priority_tree[$clog2(IRQ_COUNT)] >> 1);
    
    assign masked_interrupts = masked_input;
    assign highest_irq = highest_priority[$clog2(IRQ_COUNT)-1:0];
    assign irq_active = |masked_input;

endmodule