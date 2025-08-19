//SystemVerilog
module AsyncMaskITRC #(parameter IRQ_COUNT=4) (
    input wire [IRQ_COUNT-1:0] interrupt_lines,
    input wire [IRQ_COUNT-1:0] mask_bits,
    output wire [IRQ_COUNT-1:0] masked_interrupts,
    output wire [$clog2(IRQ_COUNT)-1:0] highest_irq,
    output wire irq_active
);

    wire [IRQ_COUNT-1:0] effective_irq = interrupt_lines & ~mask_bits;
    wire [IRQ_COUNT-1:0] priority_mask;
    wire [IRQ_COUNT-1:0] priority_sel;
    wire [$clog2(IRQ_COUNT)-1:0] prio_idx;
    
    // Optimized priority encoder using parallel prefix
    genvar i;
    generate
        for (i = 0; i < IRQ_COUNT; i = i + 1) begin : gen_prio
            if (i == 0) begin
                assign priority_mask[i] = effective_irq[i];
                assign priority_sel[i] = effective_irq[i];
            end else begin
                assign priority_mask[i] = priority_mask[i-1] | effective_irq[i];
                assign priority_sel[i] = effective_irq[i] & ~priority_mask[i-1];
            end
        end
    endgenerate

    // Binary encoder for priority selection
    generate
        for (i = 0; i < $clog2(IRQ_COUNT); i = i + 1) begin : gen_enc
            wire [IRQ_COUNT-1:0] bit_mask = (1 << i);
            assign prio_idx[i] = |(priority_sel & bit_mask);
        end
    endgenerate

    assign masked_interrupts = effective_irq;
    assign highest_irq = prio_idx;
    assign irq_active = |effective_irq;

endmodule