//SystemVerilog
// Pipelined version of IVMU_NestingCtrl
// This module implements a 2-stage pipeline for the nesting level control logic.
// Latency is increased to 2 cycles, but potentially allows for higher clock frequency.
module IVMU_NestingCtrl_Pipelined #(parameter LVL=3) (
    input clk, rst,
    input [LVL-1:0] int_lvl,
    output reg [LVL-1:0] current_lvl, // Final output state
    output reg valid_out // Indicates when current_lvl is valid
);

// --- Pipeline Registers ---
// Stage 1 registers: Hold inputs and state for Stage 2
reg [LVL-1:0] int_lvl_stage1;
reg [LVL-1:0] current_lvl_stage1; // State value from previous cycle, used in Stage 1 logic
reg rst_stage1; // Propagate reset through pipeline
reg valid_stage1; // Valid signal for Stage 1 output

// Stage 2 registers: Hold intermediate results from Stage 1 for Stage 2 combinational logic
reg int_lvl_nonzero_stage1;
reg int_lvl_greater_stage1;

// Stage 2 computation result (combinational)
reg [LVL-1:0] next_current_lvl_stage2;

// Stage 2 valid signal (registered)
reg valid_stage2_reg;


// --- Stage 1: Register inputs and compute intermediate conditions ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        int_lvl_stage1 <= 0; // Reset value for pipeline register
        current_lvl_stage1 <= 0; // Reset value for pipeline register
        rst_stage1 <= 1; // Propagate reset condition
        valid_stage1 <= 0; // In reset, Stage 1 output is not valid
        int_lvl_nonzero_stage1 <= 0;
        int_lvl_greater_stage1 <= 0;
    end else begin
        // Register inputs for Stage 2
        int_lvl_stage1 <= int_lvl;
        current_lvl_stage1 <= current_lvl; // Use the current state value as input to the pipeline
        rst_stage1 <= 0; // Not in reset this cycle

        // Compute intermediate results combinatorially in Stage 1 and register them
        int_lvl_nonzero_stage1 <= (|int_lvl);
        int_lvl_greater_stage1 <= (int_lvl > current_lvl);

        // Stage 1 output is valid if not in reset
        valid_stage1 <= 1;
    end
end

// --- Stage 2: Compute next state based on registered results from Stage 1 ---
always @(*) begin
    // Default assignment: retain the registered current_lvl from Stage 1
    next_current_lvl_stage2 = current_lvl_stage1;

    // Case statement based on registered conditions and rst
    case ({rst_stage1, int_lvl_nonzero_stage1, int_lvl_greater_stage1})
        // Case 1: Registered reset is active
        3'b1xx: begin
            next_current_lvl_stage2 = 0;
        end

        // Case 2: Not registered reset, int_lvl non-zero, and int_lvl > current_lvl
        3'b011: begin
            next_current_lvl_stage2 = int_lvl_stage1; // Use registered int_lvl
        end

        // Case 3: Not registered reset, int_lvl non-zero, and int_lvl <= current_lvl
        // 3'b010: Handled by default assignment
        3'b010: begin
            // No change from default assignment
        end

        // Case 4: Not registered reset, int_lvl is zero
        // 3'b00x covers 3'b000 and unreachable 3'b001
        3'b00x: begin
            next_current_lvl_stage2 = 0;
        end

        // Default case: Retain registered current_lvl
        default: begin
            next_current_lvl_stage2 = current_lvl_stage1;
        end
    endcase
end

// --- Stage 2 Output Register: Update final state and valid output ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_lvl <= 0; // Reset final state
        valid_stage2_reg <= 0; // Reset Stage 2 valid signal
        valid_out <= 0; // Reset final output valid signal
    end else begin
        // Update final state and valid signal if Stage 1 output was valid
        // This effectively propagates the valid signal through the pipeline
        if (valid_stage1) begin
             current_lvl <= next_current_lvl_stage2; // Register the computed next state
             valid_stage2_reg <= 1; // Stage 2 output is valid one cycle after Stage 1 output is valid
        end else begin
             // If Stage 1 was not valid (e.g., during pipeline flush after reset),
             // the output should also be considered invalid.
             // We might choose to hold the previous value or reset to a default.
             // Resetting to 0 mirrors the reset behavior during invalid periods.
             current_lvl <= 0;
             valid_stage2_reg <= 0;
        end
         // The final valid output is simply the registered Stage 2 valid signal
         valid_out <= valid_stage2_reg;
    end
end

endmodule