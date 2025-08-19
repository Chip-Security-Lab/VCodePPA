//SystemVerilog
module IVMU_Suppression_pipelined #(parameter MASK_W=8) (
    input clk,
    input rst, // Synchronous reset
    input global_mask,
    input [MASK_W-1:0] irq,
    input input_valid, // Input valid signal to the pipeline

    output [MASK_W-1:0] valid_irq,
    output output_valid // Output valid signal from the pipeline
);

// Stage 1 Registers: Register inputs and valid signal
reg global_mask_s1;
reg [MASK_W-1:0] irq_s1;
reg valid_s1; // Valid signal propagated to Stage 2

// Retimed Registers: Register outputs of Stage 1 before combinatorial logic
// These registers replace the original Stage 2 registers by moving them backward
reg global_mask_r;
reg [MASK_W-1:0] irq_r;
reg valid_r; // Registers valid_s1 for output valid

// Combinatorial logic output
wire [MASK_W-1:0] valid_irq_comb;

always @(posedge clk) begin
    if (rst) begin
        // Reset all pipeline registers
        global_mask_s1 <= 1'b0;
        irq_s1 <= {MASK_W{1'b0}};
        valid_s1 <= 1'b0;
        // Reset retimed registers
        global_mask_r <= 1'b0;
        irq_r <= {MASK_W{1'b0}};
        valid_r <= 1'b0;
    end else begin
        // Stage 1: Register inputs and propagate valid
        global_mask_s1 <= global_mask;
        irq_s1 <= irq;
        valid_s1 <= input_valid;

        // Retimed stage: Register outputs of Stage 1
        // These registers feed the combinatorial logic and the output valid signal
        global_mask_r <= global_mask_s1;
        irq_r <= irq_s1;
        valid_r <= valid_s1;
    end
end

// Combinatorial logic now operates on the retimed registers
// This logic was originally computed and then registered in valid_irq_s2
assign valid_irq_comb = global_mask_r ? {MASK_W{1'b0}} : irq_r;

// Assign final outputs from the combinatorial logic and the retimed valid register
// The original valid_irq_s2 and valid_s2 registers are removed,
// and their function is replaced by the combinatorial logic and valid_r register
assign valid_irq = valid_irq_comb;
assign output_valid = valid_r;

endmodule