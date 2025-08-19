//SystemVerilog
// Top module: IVMU_DualTrigger_Top
// Refactored IVMU_DualTrigger module into hierarchical submodules.
// This structure aims to maintain the original functional behavior and timing dependencies.
module IVMU_DualTrigger_Top (
    input wire clk,
    input wire edge_mode,
    input wire async_irq,
    output wire sync_irq
);

// Internal wire to connect the output of the input register to the logic module
wire last_async_irq_val;

// Instantiate the module that registers the asynchronous input
async_input_register u_async_input_register (
    .clk                 (clk),
    .async_in            (async_irq),
    .registered_async_in (last_async_irq_val)
);

// Instantiate the module that performs the trigger logic and registers the output
mode_trigger_logic u_mode_trigger_logic (
    .clk                 (clk),
    .current_async_in    (async_irq),          // Pass the raw asynchronous input
    .registered_async_in (last_async_irq_val), // Pass the registered input
    .edge_mode           (edge_mode),
    .sync_trigger_out    (sync_irq)            // Connect to the top-level output
);

endmodule

// Submodule: async_input_register
// Registers the asynchronous input by one clock cycle.
// Note: This single register does NOT provide robust synchronization for asynchronous inputs.
module async_input_register (
    input wire clk,
    input wire async_in,
    output reg registered_async_in
);

always @(posedge clk) begin
    registered_async_in <= async_in;
end

endmodule

// Submodule: mode_trigger_logic
// Implements the level or edge triggering logic and registers the final output.
// It uses the current asynchronous input and its one-cycle-delayed registered version.
module mode_trigger_logic (
    input wire clk,
    input wire current_async_in,     // Raw asynchronous input
    input wire registered_async_in,  // Asynchronous input registered by one cycle
    input wire edge_mode,            // 0: Level trigger, 1: Positive edge trigger
    output reg sync_trigger_out
);

// Combinatorial logic result before output registration
wire trigger_comb_result;

// The logic uses the current asynchronous input directly, which might lead to timing issues.
assign trigger_comb_result = current_async_in & (~edge_mode | ~registered_async_in);

always @(posedge clk) begin
    // Register the combinatorial result to produce the synchronous output
    sync_trigger_out <= trigger_comb_result;
end

endmodule