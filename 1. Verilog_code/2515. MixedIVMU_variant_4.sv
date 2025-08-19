//SystemVerilog
// vector_table_rom module
// Stores and provides interrupt vectors based on index.
module vector_table_rom (
    input [2:0] index,      // Input index to select vector (0-7)
    output reg [31:0] vector_out // Output interrupt vector
);

    // Combinational logic to look up vector based on index
    always @(*) begin
        case (index)
            3'd0: vector_out = 32'hD000_0000;
            3'd1: vector_out = 32'hD000_0080;
            3'd2: vector_out = 32'hD000_0100;
            3'd3: vector_out = 32'hD000_0180;
            3'd4: vector_out = 32'hD000_0200;
            3'd5: vector_out = 32'hD000_0280;
            3'd6: vector_out = 32'hD000_0300;
            3'd7: vector_out = 32'hD000_0380;
            default: vector_out = 32'h0; // Default for safety, index should be 0-7
        endcase
    end

endmodule

// async_edge_detector module
// Detects rising edges on asynchronous input signals.
module async_edge_detector (
    input clk,          // Clock signal
    input rst_n,        // Asynchronous reset (active low)
    input [3:0] async_in, // Asynchronous input signals
    output wire [3:0] async_edge_out // Output signals indicating rising edge
);

    reg [3:0] async_prev; // Register to store previous state of async_in

    // Synchronous register for previous state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            async_prev <= 4'h0;
        end else begin
            async_prev <= async_in;
        end
    end

    // Combinational logic to detect rising edge (current high & previous low)
    assign async_edge_out = async_in & ~async_prev;

endmodule

// irq_latcher_arbiter module
// Latches synchronous and asynchronous interrupt requests, handles acknowledgment,
// prioritizes requests, and outputs the selected interrupt index and pending status.
module irq_latcher_arbiter (
    input clk,              // Clock signal
    input rst_n,            // Asynchronous reset (active low)
    input [3:0] sync_in,    // Synchronous interrupt requests (level/pulse)
    input [3:0] async_edge_in, // Asynchronous interrupt rising edges
    input ack,              // Acknowledgment signal to clear latched requests
    output reg [2:0] irq_index_out,  // Output index of the highest priority interrupt (0-7)
    output reg irq_select_valid, // Indicates if a valid interrupt is selected by the arbiter
    output wire irq_pending_out // Indicates if any interrupt is pending
);

    reg [3:0] sync_latched;  // Latched synchronous requests
    reg [3:0] async_latched; // Latched asynchronous requests

    // Latch requests and clear on acknowledgment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_latched <= 4'h0;
            async_latched <= 4'h0;
        end else begin
            // Latch new requests (ORing with current latched state)
            async_latched <= async_latched | async_edge_in;
            sync_latched <= sync_latched | sync_in;

            // Clear latched requests if acknowledgment is asserted
            if (ack) begin
                sync_latched <= 4'h0;
                async_latched <= 4'h0;
            end
        end
    end

    // Priority encoder to select the highest priority interrupt and determine index/validity
    // Priority: async_latched[3] > async_latched[2] > ... > async_latched[0] >
    //           sync_latched[3] > sync_latched[2] > ... > sync_latched[0]
    always @(*) begin
        irq_select_valid = 1'b1; // Assume valid unless no interrupt is pending
        if (async_latched[3]) begin
            irq_index_out = 3'd7;
        end else if (async_latched[2]) begin
            irq_index_out = 3'd6;
        end else if (async_latched[1]) begin
            irq_index_out = 3'd5;
        end else if (async_latched[0]) begin
            irq_index_out = 3'd4;
        end else if (sync_latched[3]) begin
            irq_index_out = 3'd3;
        end else if (sync_latched[2]) begin
            irq_index_out = 3'd2;
        end else if (sync_latched[1]) begin
            irq_index_out = 3'd1;
        end else if (sync_latched[0]) begin
            irq_index_out = 3'd0;
        end else begin
            // No interrupt pending or selected
            irq_index_out = 3'd0; // Default index when no interrupt is selected
            irq_select_valid = 1'b0; // Indicate that no interrupt is currently selected
        end
    end

    // Overall IRQ pending status (OR of all latched requests)
    assign irq_pending_out = |sync_latched | |async_latched;

endmodule

// Top module: MixedIVMU_refactored
// Integrates sub-modules to provide the complete interrupt vectoring functionality.
module MixedIVMU_refactored (
    input clk,          // Clock signal
    input rst_n,        // Asynchronous reset (active low)
    input [3:0] sync_irq, // Synchronous interrupt requests
    input [3:0] async_irq, // Asynchronous interrupt requests
    input ack,          // Acknowledgment signal
    output reg [31:0] vector, // Output interrupt vector
    output wire irq_pending // Output interrupt pending status
);

    // Internal wires to connect sub-modules
    wire [3:0] async_edge;              // Rising edges of async_irq
    wire [2:0] irq_arbiter_index;       // Index from arbiter
    wire irq_arbiter_select_valid;    // Validity signal from arbiter
    wire irq_arbiter_pending;         // Overall pending status from arbiter
    wire [31:0] selected_vector_from_rom; // Vector retrieved from ROM

    // Instantiate sub-modules

    // Instance of Async Edge Detector
    async_edge_detector i_async_edge_detector (
        .clk(clk),
        .rst_n(rst_n),
        .async_in(async_irq),
        .async_edge_out(async_edge)
    );

    // Instance of Interrupt Latcher and Arbiter
    irq_latcher_arbiter i_irq_latcher_arbiter (
        .clk(clk),
        .rst_n(rst_n),
        .sync_in(sync_irq),
        .async_edge_in(async_edge),
        .ack(ack),
        .irq_index_out(irq_arbiter_index),
        .irq_select_valid(irq_arbiter_select_valid),
        .irq_pending_out(irq_arbiter_pending)
    );

    // Instance of Vector Table ROM
    vector_table_rom i_vector_table_rom (
        .index(irq_arbiter_index),
        .vector_out(selected_vector_from_rom)
    );

    // Output assignments

    // Connect the overall pending status from the arbiter to the top-level output
    assign irq_pending = irq_arbiter_pending;

    // Register to hold the output vector
    // Update the vector only when not acknowledging AND a valid interrupt is selected by the arbiter.
    // This replicates the conditional update behavior of the original code's vector assignment.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vector <= 32'h0; // Reset vector on reset
        end else begin
            // Update vector if ack is not asserted AND the arbiter has selected a valid interrupt
            if (!ack && irq_arbiter_select_valid) begin
                vector <= selected_vector_from_rom;
            end
            // If ack is asserted OR no valid interrupt is selected, the vector retains its previous value.
        end
    end

endmodule