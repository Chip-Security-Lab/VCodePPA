//SystemVerilog
// Top module: IVMU_DelayArbiter
// Orchestrates the delay counter and grant logic submodules.
module IVMU_DelayArbiter #(
    parameter DELAY = 3 // Parameter for the delay period
) (
    input clk,         // Clock signal
    input [3:0] irq,   // Input interrupt requests (priority: 0 > 1 > 2)
    output [1:0] grant // Output granted channel (0, 1, or 2)
);

    // Internal signals for state and next state communication between submodules
    wire [DELAY-1:0] current_cnt;     // Current registered counter value
    wire [1:0] current_grant_reg; // Current registered grant value
    wire [DELAY-1:0] next_cnt;        // Calculated next counter value
    wire [1:0] next_grant;         // Calculated next grant value
    wire enable_update;            // Signal to enable state register update (|irq)

    // Determine when to enable state updates: any IRQ being high
    assign enable_update = |irq;

    // Instantiate State Registers module: Holds the current state (counter and grant)
    // Updates the state registers on the positive clock edge when enabled.
    arbiter_state_registers #(
        .DELAY(DELAY)
    ) i_state_registers (
        .clk(clk),                   // Clock
        .enable_update(enable_update), // Enable signal from top module
        .cnt_next(next_cnt),         // Input: Next counter value from logic module
        .grant_next(next_grant),     // Input: Next grant value from logic module
        .cnt_out(current_cnt),       // Output: Current registered counter value
        .grant_out(current_grant_reg)  // Output: Current registered grant value
    );

    // Instantiate Next State Logic module: Computes the next state based on current state and inputs
    // This module is purely combinational.
    arbiter_next_state_logic #(
        .DELAY(DELAY)
    ) i_next_state_logic (
        .cnt_current(current_cnt),       // Input: Current counter value from state module
        .grant_current(current_grant_reg), // Input: Current grant value from state module
        .irq(irq),                       // Input: IRQ signals
        .cnt_next(next_cnt),             // Output: Calculated next counter value
        .grant_next(next_grant)          // Output: Calculated next grant value
    );

    // Connect the registered grant output from the state module to the top-level output
    assign grant = current_grant_reg;

endmodule

// arbiter_state_registers submodule: Registers for counter and grant
// This module contains the state elements (registers) and updates them.
module arbiter_state_registers #(
    parameter DELAY = 3 // Parameter for the counter width (derived from DELAY)
) (
    input clk,               // Clock signal
    input enable_update,     // Control signal to update registers (|irq)
    input [DELAY-1:0] cnt_next, // Input: Calculated next value for counter
    input [1:0] grant_next,  // Input: Calculated next value for grant
    output reg [DELAY-1:0] cnt_out, // Output: Current registered counter value
    output reg [1:0] grant_out  // Output: Current registered grant value
);

    // Initialize registers at simulation start
    initial begin
        cnt_out = {DELAY{1'b0}}; // Counter starts at 0
        grant_out = 2'b00;       // Grant starts at 0
    end

    // Update registers on the positive clock edge
    always @(posedge clk) begin
        if (enable_update) begin
            // Latch the next state values when update is enabled
            cnt_out <= cnt_next;
            grant_out <= grant_next;
        end
        // If enable_update is low, registers hold their values
    end

endmodule

// arbiter_next_state_logic submodule: Combinational logic for next state calculation
// This module contains the combinational logic to determine the next state values
// based on the current state and inputs.
module arbiter_next_state_logic #(
    parameter DELAY = 3 // Parameter for counter width (used for comparison)
) (
    input [DELAY-1:0] cnt_current,   // Input: Current counter value
    input [1:0] grant_current,   // Input: Current grant value
    input [3:0] irq,           // Input: IRQ signals
    output wire [DELAY-1:0] cnt_next, // Output: Calculated next counter value
    output wire [1:0] grant_next  // Output: Calculated next grant value
);

    // Calculate the next counter value: increment unless at DELAY-1, then wrap to 0
    wire [DELAY-1:0] calculated_cnt_next;
    assign calculated_cnt_next = (cnt_current == DELAY - 1) ? {DELAY{1'b0}} : cnt_current + 1;

    // Calculate the potential next grant value based on IRQ priority (0 > 1 > 2)
    // This value is used only when the counter is zero.
    wire [1:0] calculated_grant_value_when_zero;
    assign calculated_grant_value_when_zero = irq[0] ? 2'd0 :
                                              irq[1] ? 2'd1 :
                                              irq[2] ? 2'd2 :
                                              2'd2; // Matches original logic if irq[0..2] are all low

    // Determine the actual next grant value:
    // - If the current count is 0, the next grant is determined by IRQ priority.
    // - If the current count is not 0, the next grant is the current grant value (hold).
    assign grant_next = (cnt_current == {DELAY{1'b0}}) ? calculated_grant_value_when_zero : grant_current;

    // The next counter value is always the calculated one when the state register update is enabled
    // (the enable_update signal in the state register module handles the conditional update).
    assign cnt_next = calculated_cnt_next;

endmodule