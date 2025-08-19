//SystemVerilog
module MixedIVMU (
    input clk, rst_n,
    input [3:0] sync_irq,
    input [3:0] async_irq,
    input ack, // Acknowledge input (from receiver)
    output reg [31:0] vector, // Data output
    output wire req // Request output (to receiver)
);
    reg [31:0] vectors [0:7];
    reg [3:0] sync_pending, async_latched;
    reg [3:0] async_prev;
    wire [3:0] async_edge;

    // Initialization of vector table
    initial begin
        vectors[0] = 32'hD000_0000;
        vectors[1] = 32'hD000_0080;
        vectors[2] = 32'hD000_0100;
        vectors[3] = 32'hD000_0180;
        vectors[4] = 32'hD000_0200;
        vectors[5] = 32'hD000_0280;
        vectors[6] = 32'hD000_0300;
        vectors[7] = 32'hD000_0380;
    end

    // Calculate async edge detection
    assign async_edge = async_irq & ~async_prev;

    // Combine pending interrupts for priority encoding
    wire [7:0] all_pending_interrupts = {async_latched, sync_pending};

    // Priority encoder logic
    reg [2:0] priority_index;
    reg any_interrupt_pending; // Used internally for vector update logic

    always @(*) begin
        priority_index = 3'h0; // Default index (lowest priority)
        any_interrupt_pending = 1'b0;
        // Use a case statement for priority encoding, checking from MSB to LSB
        case (1'b1)
            all_pending_interrupts[7]: begin priority_index = 3'd7; any_interrupt_pending = 1'b1; end // async_latched[3]
            all_pending_interrupts[6]: begin priority_index = 3'd6; any_interrupt_pending = 1'b1; end // async_latched[2]
            all_pending_interrupts[5]: begin priority_index = 3'd5; any_interrupt_pending = 1'b1; end // async_latched[1]
            all_pending_interrupts[4]: begin priority_index = 3'd4; any_interrupt_pending = 1'b1; end // async_latched[0]
            all_pending_interrupts[3]: begin priority_index = 3'd3; any_interrupt_pending = 1'b1; end // sync_pending[3]
            all_pending_interrupts[2]: begin priority_index = 3'd2; any_interrupt_pending = 1'b1; end // sync_pending[2]
            all_pending_interrupts[1]: begin priority_index = 3'd1; any_interrupt_pending = 1'b1; end // sync_pending[1]
            all_pending_interrupts[0]: begin priority_index = 3'd0; any_interrupt_pending = 1'b1; end // sync_pending[0]
            default: begin priority_index = 3'h0; any_interrupt_pending = 1'b0; end // No interrupts pending
        endcase
    end

    // Request signal (equivalent to original irq_pending/valid)
    // High when any interrupt is pending, indicating data (vector) is available.
    assign req = |sync_pending | |async_latched;

    // Sequential logic for state updates and vector selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_pending <= 4'h0;
            async_latched <= 4'h0;
            async_prev <= 4'h0;
            vector <= 32'h0; // Reset vector to a known state
        end else begin
            // Update previous state for edge detection
            async_prev <= async_irq;

            // Latch new pending interrupts (sync level, async edge)
            // Interrupts are latched regardless of handshake state
            async_latched <= async_latched | async_edge;
            sync_pending <= sync_pending | sync_irq;

            // Handle acknowledge and vector update
            // Clear pending interrupts upon acknowledge (Req & Ack handshake)
            if (ack) begin
                // Clear all pending interrupts when ack is asserted
                // Note: This clears ALL pending, not just the one currently presented by vector
                sync_pending <= 4'h0;
                async_latched <= 4'h0;
            end
            // Update vector based on highest priority pending interrupt *only if not acknowledged*
            // This preserves the original timing where vector is stable while req is high and ack is low
            else begin
                 if (any_interrupt_pending) begin
                    vector <= vectors[priority_index];
                end
                // If no interrupt is pending and not acknowledged, vector holds its previous value.
                // If ack is high, vector also holds its previous value while pending is cleared.
            end
        end
    end

endmodule