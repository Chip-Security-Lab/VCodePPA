//SystemVerilog
// Refactored into a single module with separated logic blocks
module IVMU_Suppression_Refactored #(
    parameter MASK_W = 8
) (
    input clk,         // Clock signal
    input global_mask, // Global mask signal (active high)
    input [MASK_W-1:0] irq,           // Input interrupt vector
    output [MASK_W-1:0] valid_irq     // Output valid interrupt vector (registered and masked)
);

    // Internal wire for combinational output
    wire [MASK_W-1:0] masked_irq_comb;

    // Internal register for sequential output
    reg [MASK_W-1:0] valid_irq_reg;

    // --- Combinational Logic Block ---
    // Applies the global mask to the interrupt vector
    // Use assign for pure combinational logic
    assign masked_irq_comb = global_mask ? {MASK_W{1'b0}} : irq;

    // --- Sequential Logic Block ---
    // Registers the masked signal on the positive clock edge
    // Use always @(posedge clk) for pure sequential logic
    always @(posedge clk) begin
        valid_irq_reg <= masked_irq_comb;
    end

    // --- Output Assignment ---
    // Connect the registered value to the module output
    // Use assign for connecting internal reg to output port
    assign valid_irq = valid_irq_reg;

endmodule