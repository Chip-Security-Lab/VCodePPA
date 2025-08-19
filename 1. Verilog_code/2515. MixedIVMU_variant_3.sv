//SystemVerilog
module MixedIVMU (
    input clk,
    input rst_n,
    input [3:0] sync_irq,
    input [3:0] async_irq,
    input ack, // Mapped from original 'ack' (Ready) to Req-Ack 'ack'
    output reg [31:0] vector,
    output wire req // Mapped from original 'irq_pending' (Valid) to Req-Ack 'req'
);
    reg [31:0] vectors [0:7];
    reg [3:0] sync_pending, async_latched;
    reg [3:0] async_prev;
    wire [3:0] async_edge;
    integer i;

    // Initialization remains the same
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

    // Async edge detection remains the same
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            async_prev <= 4'h0;
        end else begin
            async_prev <= async_irq;
        end
    end

    // Calculate edge remains the same
    assign async_edge = async_irq & ~async_prev;

    // Main state logic remains the same, using 'ack' input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_pending <= 4'h0;
            async_latched <= 4'h0;
            vector <= 32'h0;
        end else begin
            // Accumulate pending interrupts
            async_latched <= async_latched | async_edge;
            sync_pending <= sync_pending | sync_irq;

            // Handshake logic: Clear pending state when ack is received
            // Note: This clears state on the cycle *after* ack is asserted.
            if (ack) begin
                sync_pending <= 4'h0;
                async_latched <= 4'h0;
            end else begin
                // Select vector only when not acknowledged (holding data)
                if (async_latched[3]) begin
                    vector <= vectors[7];
                end else if (async_latched[2]) begin
                    vector <= vectors[6];
                end else if (async_latched[1]) begin
                    vector <= vectors[5];
                end else if (async_latched[0]) begin
                    vector <= vectors[4];
                end else if (sync_pending[3]) begin
                    vector <= vectors[3];
                end else if (sync_pending[2]) begin
                    vector <= vectors[2];
                end else if (sync_pending[1]) begin
                    vector <= vectors[1];
                end else if (sync_pending[0]) begin
                    vector <= vectors[0];
                end
                // If no interrupts are pending and not acknowledged, vector holds previous value.
                // This seems consistent with the original logic.
            end
        end
    end

    // Request signal (formerly irq_pending)
    // Asserted when any interrupt is pending.
    // This signals to the receiver that 'vector' is valid.
    assign req = |sync_pending | |async_latched;

endmodule