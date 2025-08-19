//SystemVerilog
module IVMU_Suppression_Pipelined #(parameter MASK_W=8) (
    input clk,
    input rst_n, // Asynchronous reset active low
    input i_valid, // Input valid signal
    input global_mask,
    input [MASK_W-1:0] irq,
    output o_valid, // Output valid signal
    output [MASK_W-1:0] valid_irq
);

// Stage 0: Input Registration
reg [MASK_W-1:0] irq_s0;
reg global_mask_s0;
reg valid_s0;

// Stage 1: Logic and Output Registration
wire [MASK_W-1:0] result_s1_comb;
reg [MASK_W-1:0] result_s1;
reg valid_s1;

// Stage 0 Registers
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        irq_s0 <= {MASK_W{1'b0}};
        global_mask_s0 <= 1'b0;
        valid_s0 <= 1'b0;
    end else begin
        // Register inputs and valid signal from input
        irq_s0 <= irq;
        global_mask_s0 <= global_mask;
        valid_s0 <= i_valid; // Propagate input valid signal
    end
end

// Stage 1 Logic (Combinational)
// Performs the suppression logic using the registered inputs from Stage 0
// Implemented using a structure based on conditional inversion algorithm carry logic
wire mask_enable; // Control signal for conditional inversion (~global_mask_s0)

assign mask_enable = ~global_mask_s0; // Active low mask enables the IRQ

generate
  for (genvar i = 0; i < MASK_W; i++) begin : bit_logic_using_carry
    // Inputs to the hypothetical bit slice for carry calculation
    wire Ai = irq_s0[i]; // First operand bit
    wire Bi = 1'b0; // Second operand bit is always 0
    wire Cin = 1'b0; // Carry-in bit is always 0
    wire control = mask_enable; // Control signal for conditional inversion of Bi

    // Step 1: Conditional inversion of Bi
    // Bi_modified = Bi ^ control
    wire Bi_modified = Bi ^ control; // = 1'b0 ^ mask_enable = mask_enable

    // Step 2: Compute Ai ^ Bi_modified (needed for carry formula)
    wire Ai_xor_Bi_modified = Ai ^ Bi_modified;

    // Step 3: Compute Carry-Out using the formula (A & B_modified) | (Cin & (A ^ B_modified))
    wire Cout = (Ai & Bi_modified) | (Cin & Ai_xor_Bi_modified);
    // Substituting values: Cout = (irq_s0[i] & mask_enable) | (1'b0 & Ai_xor_Bi_modified)
    // Cout = irq_s0[i] & mask_enable;
    // This implements irq_s0[i] AND (NOT global_mask_s0)

    // The result for this bit is the carry-out of this structure
    assign result_s1_comb[i] = Cout;
  end
endgenerate


// Stage 1 Registers (Output Registration)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result_s1 <= {MASK_W{1'b0}};
        valid_s1 <= 1'b0;
    end else begin
        // Register the result of Stage 1 logic and propagate valid signal from Stage 0
        result_s1 <= result_s1_comb;
        valid_s1 <= valid_s0; // Propagate valid signal through the pipeline
    end
end

// Output assignments
assign valid_irq = result_s1; // Output data comes from the last stage register
assign o_valid = valid_s1;   // Output valid signal comes from the last stage valid register

endmodule