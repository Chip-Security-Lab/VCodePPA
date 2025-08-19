//SystemVerilog
// SystemVerilog
module IVMU_AutoClear_Pipelined #(parameter W=8) (
    input clk,
    input ack,
    input [W-1:0] irq,
    output reg [W-1:0] active_irq
);

// Pipeline Stage 1 Registers
reg [W-1:0] irq_s1;
reg ack_s1;
reg [W-1:0] active_irq_s1; // Propagate previous state for Stage 1 calculation

// Stage 1: Calculate the potential next value (OR operation)
// This stage uses the registered previous state (active_irq_s1) and registered current input (irq_s1)
// The actual calculation uses the values available at the start of the stage
// For the first stage, we use the current inputs and the previous cycle's output state
wire [W-1:0] stage1_or_comb = active_irq | irq; // Uses current irq and previous active_irq

// Register inputs and intermediate result for Stage 2
always @(posedge clk) begin
    // Assuming no reset based on original code
    irq_s1 <= irq;
    ack_s1 <= ack;
    active_irq_s1 <= stage1_or_comb; // Register the result of the OR operation
end

// Pipeline Stage 2 Registers (Implicitly active_irq is the stage 2 output register)
// No explicit registers needed here as active_irq is the final output register

// Stage 2: Apply the acknowledge logic
// Uses registered signals from Stage 1
wire [W-1:0] stage2_next_active_irq_comb = ack_s1 ? {W{1'b0}} : active_irq_s1;

// Update the main state register (Output of Stage 2)
always @(posedge clk) begin
    // Assuming no reset based on original code
    active_irq <= stage2_next_active_irq_comb;
end

endmodule