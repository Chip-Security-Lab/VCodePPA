//SystemVerilog
module IVMU_DualTrigger_pipelined (
    input clk,
    input rst_n, // Active low reset
    input edge_mode,
    input async_irq,
    // Valid-Ready handshake interface for the output
    output reg sync_irq_valid, // Indicates sync_irq is valid
    input sync_irq_ready,      // Indicates receiver is ready to accept sync_irq
    output reg sync_irq        // The data payload (interrupt state)
);

// Stage 1 Registers: Synchronization and Input Registration
reg async_irq_sync1_stage1; // First stage of async synchronizer
reg async_irq_sync2_stage1; // Second stage of async synchronizer (Synchronized async_irq)
reg edge_mode_stage1;       // Registered edge_mode

// Stage 2 Logic (Combinational based on Stage 1 registers)
wire sync_irq_stage2_logic; // The source signal that potentially triggers an output event

// Output Stage Intermediate signal
wire generate_new_output; // Indicates if a new output event should be generated

//----------------------------------------------------------------------
// Stage 1: Input Synchronization and Registration
//----------------------------------------------------------------------

// async_irq synchronizer
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        async_irq_sync1_stage1 <= 1'b0;
        async_irq_sync2_stage1 <= 1'b0;
    end else begin
        // 2-flop synchronizer for async_irq
        async_irq_sync1_stage1 <= async_irq;
        async_irq_sync2_stage1 <= async_irq_sync1_stage1; // Synchronized async_irq (current)
    end
end

// edge_mode registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        edge_mode_stage1 <= 1'b0;
    end else begin
        // Register edge_mode
        edge_mode_stage1 <= edge_mode;
    end
end

//----------------------------------------------------------------------
// Stage 2: Logic Calculation (Combinational)
//----------------------------------------------------------------------
// This logic produces a pulse (edge mode) or level (level mode) based on synchronized input
assign sync_irq_stage2_logic = edge_mode_stage1 ?
                              (async_irq_sync2_stage1 & ~async_irq_sync1_stage1) : // Rising edge detection on synchronized signal
                              async_irq_sync2_stage1;                             // Simple synchronization

//----------------------------------------------------------------------
// Output Stage: Valid-Ready Handshake Implementation
//----------------------------------------------------------------------

// Determine if a new output event can be generated and sent
// A new event is triggered when sync_irq_stage2_logic is high
// We can generate a new output if the event is high AND (the previous output is not valid OR the receiver is ready)
assign generate_new_output = sync_irq_stage2_logic && (!sync_irq_valid || sync_irq_ready);

// Update sync_irq_valid state
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sync_irq_valid <= 1'b0;
    end else begin
        if (generate_new_output) begin
            // A new event is generated and can be sent -> assert valid
            sync_irq_valid <= 1'b1;
        end else if (sync_irq_valid && sync_irq_ready) begin
            // The current valid data was accepted by the receiver -> deassert valid
            sync_irq_valid <= 1'b0;
        end
        // If sync_irq_valid is high and sync_irq_ready is low, sync_irq_valid holds high (backpressure).
    end
end

// Update sync_irq (the payload) state
// The payload is the event itself, typically 1'b1 when an interrupt is asserted.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sync_irq <= 1'b0;
    end else begin
        if (generate_new_output) begin
            // A new event is generated -> set payload to 1'b1
            sync_irq <= 1'b1;
        end else if (sync_irq_valid && sync_irq_ready) begin
             // The current valid payload was consumed -> clear the payload
             sync_irq <= 1'b0;
        end
        // If sync_irq_valid is high and sync_irq_ready is low, sync_irq holds its value (1'b1).
    end
end

endmodule