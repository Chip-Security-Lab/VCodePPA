//SystemVerilog
module IVMU_AutoClear_Pipelined #(parameter W=8) (
    input clk,
    input rst_n, // Synchronous active-low reset
    input ack,
    input [W-1:0] irq,
    output [W-1:0] active_irq
);

// Pipeline Register for Stage 1 inputs
reg [W-1:0] irq_s1_reg;
reg ack_s1_reg;

// Pipeline Register for the state/output
reg [W-1:0] active_irq_reg;

// Assign final output
assign active_irq = active_irq_reg;

// Sequential logic for pipeline registers and state update
always @(posedge clk) begin
    if (!rst_n) begin
        // Reset all pipeline registers
        irq_s1_reg <= {W{1'b0}};
        ack_s1_reg <= 1'b0;
        active_irq_reg <= {W{1'b0}};
    end else begin
        // Stage 1: Register inputs
        irq_s1_reg <= irq;
        ack_s1_reg <= ack;

        // Stage 2 Logic (Combinational): Calculate next active_irq based on registered inputs and current state
        // The original logic was active_irq_next = ack ? 0 : (active_irq_reg | irq)
        // With registered inputs (irq_s1_reg, ack_s1_reg) and feedback (active_irq_reg):
        // active_irq_next = ack_s1_reg ? {W{1'b0}} : (active_irq_reg | irq_s1_reg);
        // Restructuring the logic expression for path balancing:
        // active_irq_next = (~ack_s1_reg & active_irq_reg) | (~ack_s1_reg & irq_s1_reg);
        // This reduces the combinational depth between registers compared to the original structure
        // which had OR -> Register -> MUX -> Register.
        // This optimized version has Register -> (NOT + AND + OR) -> Register.
        active_irq_reg <= (~ack_s1_reg & active_irq_reg) | (~ack_s1_reg & irq_s1_reg);
    end
end

endmodule