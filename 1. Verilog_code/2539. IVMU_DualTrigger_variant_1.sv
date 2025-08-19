//SystemVerilog
module IVMU_DualTrigger (
    input clk,
    input edge_mode,
    input async_irq,
    output reg sync_irq
);

// Pipeline stage registers
reg async_irq_stage1; // Output of Stage 1: First synchronizer stage

// Replicated Stage 2 registers for fanout reduction of the synchronized signal
reg async_irq_stage2_repl1; // First replica of Stage 2 output
reg async_irq_stage2_repl2; // Second replica of Stage 2 output

reg async_irq_stage3; // Output of Stage 3: Previous value of synchronized async_irq (driven by one replica)
reg edge_mode_stage4; // Output of Stage 4: Pipelined edge_mode

// Intermediate wires for restructured combinational logic (Stage 5)
wire edge_detection_result;
wire level_detection_result;
wire edge_mode_selected_output;
wire level_mode_selected_output;
wire sync_irq_stage5_comb; // Final combinational output before register

always @(posedge clk) begin
    // Stage 1: First stage of asynchronous input synchronization
    async_irq_stage1 <= async_irq;

    // Stage 2: Second stage of asynchronous input synchronization
    // async_irq_stage2_repl1 and async_irq_stage2_repl2 are replicated versions
    // of the synchronized async_irq, driven by async_irq_stage1.
    async_irq_stage2_repl1 <= async_irq_stage1;
    async_irq_stage2_repl2 <= async_irq_stage1;

    // Stage 3: Register one of the replicated synchronized signals to get its previous value
    // This maintains the one-cycle difference required for edge detection.
    async_irq_stage3 <= async_irq_stage2_repl1;

    // Stage 4: Pipeline edge_mode signal to align with data path latency
    edge_mode_stage4 <= edge_mode;

    // Stage 5: Register the final output based on combinational logic
    sync_irq <= sync_irq_stage5_comb;
end

// Combinational logic for Stage 5:
// Performs edge or level detection using the pipelined and synchronized signals.
// Restructured using intermediate wires to explicitly show paths feeding the final OR/MUX,
// potentially guiding synthesis for better path balancing and timing.

// Calculate the results for edge and level detection modes
assign edge_detection_result = async_irq_stage2_repl1 & ~async_irq_stage3; // Logic for edge detection
assign level_detection_result = async_irq_stage2_repl2; // Logic for level detection

// Select the appropriate result based on the pipelined edge_mode
// These assignments create the two branches feeding the final combination
assign edge_mode_selected_output = edge_mode_stage4 & edge_detection_result; // Path when edge_mode is high
assign level_mode_selected_output = ~edge_mode_stage4 & level_detection_result; // Path when edge_mode is low

// Combine the selected paths to get the final combinational output
// This acts as the input to the final sync_irq register
assign sync_irq_stage5_comb = edge_mode_selected_output | level_mode_selected_output; // Final OR combining the two modes

endmodule