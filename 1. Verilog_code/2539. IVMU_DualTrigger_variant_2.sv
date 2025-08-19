//SystemVerilog
// Top-level module: IVMU_DualTrigger
// This module provides a synchronous trigger signal based on an asynchronous input,
// with selectable level or edge detection mode.
// It is structured hierarchically using submodules for synchronization and trigger logic.
module IVMU_DualTrigger (
    input clk,         // System clock
    input edge_mode,   // Trigger mode: 1 for edge, 0 for level
    input async_irq,   // Asynchronous input signal
    output sync_irq    // Synchronous output trigger signal
);

// Internal wire to connect the output of the synchronizer to the input of the trigger logic
wire async_irq_sync;

// Instantiate the two-stage synchronizer module
// This module synchronizes the asynchronous input to the system clock domain.
synchronizer_2stage u_synchronizer (
    .clk       (clk),       // Clock input
    .async_in  (async_irq), // Asynchronous input signal
    .sync_out  (async_irq_sync) // Synchronized output signal
);

// Instantiate the trigger logic module
// This module implements the level or edge detection logic based on the mode input.
trigger_logic u_trigger_logic (
    .clk        (clk),        // Clock input
    .sync_in    (async_irq_sync), // Synchronized input signal
    .edge_mode  (edge_mode),  // Trigger mode input
    .sync_irq   (sync_irq)    // Synchronous output trigger signal
);

endmodule

// ---------------------------------------------------------------------
// Submodule: synchronizer_2stage
// Provides a two-stage synchronization for an asynchronous input signal
// to a synchronous clock domain. This helps mitigate metastability.
// ---------------------------------------------------------------------
module synchronizer_2stage (
    input  clk,      // Clock domain for synchronization
    input  async_in, // Asynchronous input signal
    output sync_out  // Synchronized output signal (registered)
);

// Two flip-flops forming the synchronization chain
reg sync_reg1; // First stage register
reg sync_reg2; // Second stage register

// Synchronize the input signal on the positive edge of the clock
always @(posedge clk) begin
    sync_reg1 <= async_in;
    sync_reg2 <= sync_reg1; // The output is taken from the second stage
end

// Assign the output from the second stage register
assign sync_out = sync_reg2;

endmodule

// ---------------------------------------------------------------------
// Submodule: trigger_logic
// Implements trigger logic based on the 'edge_mode' input:
// - edge_mode = 1: Detects a rising edge on the 'sync_in' signal.
// - edge_mode = 0: Outputs the 'sync_in' signal directly (level trigger).
// ---------------------------------------------------------------------
module trigger_logic (
    input  clk,       // Clock domain
    input  sync_in,   // Synchronized input signal
    input  edge_mode, // Trigger mode: 1 for edge, 0 for level
    output reg sync_irq // Synchronous output trigger signal
);

// Register to store the previous value of the synchronized input
// Used specifically for rising edge detection.
reg sync_in_d1;

// Logic to generate the trigger signal based on mode
always @(posedge clk) begin
    // Capture the previous value of the synchronized input
    sync_in_d1 <= sync_in;

    // Apply the trigger logic based on the mode
    if (edge_mode) begin
        // Edge detection: Output high only on a rising edge (current high AND previous low)
        sync_irq <= sync_in & ~sync_in_d1;
    end else begin
        // Level detection: Output the synchronized signal directly
        sync_irq <= sync_in;
    end
end

endmodule