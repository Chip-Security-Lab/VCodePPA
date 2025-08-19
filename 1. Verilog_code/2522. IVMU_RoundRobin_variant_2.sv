//SystemVerilog
module IVMU_RoundRobin #(parameter int CH = 4) (
    input wire [CH-1:0] irq,
    output logic [(CH == 1 ? 0 : $clog2(CH)-1) : 0] current_ch
);

    // This block implements a priority encoder.
    // It finds the index of the highest-priority (most significant) active IRQ.
    // This is a purely combinational logic block.
    always @(*) begin
        // Default value if no IRQ is asserted.
        // Sets all bits of current_ch to 0.
        current_ch = '0;

        // Implement priority encoding by iterating from the highest priority IRQ (CH-1)
        // down to the lowest (0). The assignment for the highest 'i' where irq[i] is true
        // will be the final value of current_ch, implementing priority.
        for (int i = CH-1; i >= 0; i = i - 1) begin
            if (irq[i]) begin
                current_ch = i;
                // No 'break' is needed in combinatorial logic described this way,
                // as the loop structure naturally implies priority for synthesis.
            end
        end
    end

endmodule