//SystemVerilog
module AsyncMaskITRC #(parameter IRQ_COUNT=4) (
    input wire [IRQ_COUNT-1:0] interrupt_lines,
    input wire [IRQ_COUNT-1:0] mask_bits,
    output wire [IRQ_COUNT-1:0] masked_interrupts,
    output wire [$clog2(IRQ_COUNT)-1:0] highest_irq,
    output wire irq_active
);

    // LUT-based priority encoder
    reg [$clog2(IRQ_COUNT)-1:0] priority_lut [0:2**IRQ_COUNT-1];
    reg [IRQ_COUNT-1:0] effective_irq;
    reg [$clog2(IRQ_COUNT)-1:0] priority_id;
    
    // Initialize LUT
    integer i, j;
    initial begin
        i = 0;
        while (i < 2**IRQ_COUNT) begin
            priority_lut[i] = 0;
            j = IRQ_COUNT-1;
            while (j >= 0) begin
                if (i[j]) begin
                    priority_lut[i] = j[$clog2(IRQ_COUNT)-1:0];
                    j = -1; // break loop
                end
                j = j - 1;
            end
            i = i + 1;
        end
    end

    // Combinational logic
    always @(*) begin
        effective_irq = interrupt_lines & ~mask_bits;
        priority_id = priority_lut[effective_irq];
    end

    assign masked_interrupts = effective_irq;
    assign irq_active = |effective_irq;
    assign highest_irq = priority_id;

endmodule