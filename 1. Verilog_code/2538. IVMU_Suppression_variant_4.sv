//SystemVerilog
module IVMU_Suppression_pipelined #(parameter MASK_W=8) (
    input clk,
    input reset_n, // Active low reset
    input global_mask,
    input [MASK_W-1:0] irq,
    output [MASK_W-1:0] valid_irq
);

// Stage 1 registers: Register inputs
reg global_mask_s1;
reg [MASK_W-1:0] irq_s1;

// Stage 2 register: Register the result of the logic
reg [MASK_W-1:0] valid_irq_s2;

// Stage 1: Register inputs on the positive clock edge.
always @(posedge clk) begin
    if (!reset_n) begin
        global_mask_s1 <= 1'b0;
        irq_s1 <= '0;
    end else begin
        global_mask_s1 <= global_mask;
        irq_s1 <= irq;
    end
end

// Stage 2: Perform the suppression logic using stage 1 inputs and register the result.
always @(posedge clk) begin
    if (!reset_n) begin
        valid_irq_s2 <= '0;
    end else begin
        // Apply global mask: if global_mask_s1 is high (1), suppress all IRQs (result becomes 0).
        // If global_mask_s1 is low (0), IRQs pass through unchanged (result becomes irq_s1).
        // This logic is implemented efficiently using a bitwise AND operation.
        // When global_mask_s1 is 1, {MASK_W{~global_mask_s1}} is all 0s, resulting in result = 0.
        // When global_mask_s1 is 0, {MASK_W{~global_mask_s1}} is all 1s, resulting in result = irq_s1.
        valid_irq_s2 <= {MASK_W{~global_mask_s1}} & irq_s1;
    end
end

// Output assignment: The final output is the registered result from stage 2.
assign valid_irq = valid_irq_s2;

endmodule