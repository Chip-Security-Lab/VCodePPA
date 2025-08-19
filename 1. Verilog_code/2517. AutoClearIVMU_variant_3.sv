//SystemVerilog
module AutoClearIVMU (
    input clk, rstn,
    input [7:0] irq_in,
    input service_done,
    output reg [31:0] int_vector,
    output reg int_active
);
    reg [31:0] vector_lut [0:7];
    reg [7:0] active_irqs, pending_irqs;
    reg [2:0] current_irq;
    integer i;

    // Intermediate signals for next state calculation
    reg [2:0] next_current_irq;
    reg [31:0] next_int_vector;
    reg [7:0] next_active_irqs;
    reg [7:0] next_pending_irqs;
    reg next_int_active;

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_lut[i] = 32'hF000_0000 + (i * 16);
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            active_irqs <= 8'h0;
            pending_irqs <= 8'h0;
            int_active <= 1'b0;
            current_irq <= 3'b0;
            int_vector <= 32'b0;
        end else begin
            // Default next states are the current states
            next_active_irqs = active_irqs;
            next_pending_irqs = pending_irqs;
            next_int_active = int_active;
            next_current_irq = current_irq;
            next_int_vector = int_vector;

            // Step 1: Update pending_irqs with new requests
            next_pending_irqs = pending_irqs | irq_in;

            // Step 2: Handle service_done - clear active interrupt
            if (service_done) begin
                // Only clear if the currently active interrupt matches the one being serviced
                // Assuming service_done is for the interrupt indicated by current_irq
                next_active_irqs[current_irq] = 1'b0;
                next_int_active = 1'b0;
                // current_irq and int_vector hold the info about the just serviced interrupt
                // until a new one is activated.
            end

            // Step 3: Handle new interrupt activation - find highest priority pending
            // This happens only if no interrupt is currently active (or just became inactive)
            // AND there are pending interrupts (after incorporating irq_in and clearing serviced)
            if (!next_int_active && |next_pending_irqs) begin
                next_int_active = 1'b1;
                // Priority encoding: Find the highest set bit in next_pending_irqs
                if (next_pending_irqs[7]) begin
                    next_current_irq = 3'd7;
                    next_int_vector = vector_lut[7];
                    next_active_irqs[7] = 1'b1;
                    next_pending_irqs[7] = 1'b0; // Clear the bit that is now active
                end else if (next_pending_irqs[6]) begin
                    next_current_irq = 3'd6;
                    next_int_vector = vector_lut[6];
                    next_active_irqs[6] = 1'b1;
                    next_pending_irqs[6] = 1'b0;
                end else if (next_pending_irqs[5]) begin
                    next_current_irq = 3'd5;
                    next_int_vector = vector_lut[5];
                    next_active_irqs[5] = 1'b1;
                    next_pending_irqs[5] = 1'b0;
                end else if (next_pending_irqs[4]) begin
                    next_current_irq = 3'd4;
                    next_int_vector = vector_lut[4];
                    next_active_irqs[4] = 1'b1;
                    next_pending_irqs[4] = 1'b0;
                end else if (next_pending_irqs[3]) begin
                    next_current_irq = 3'd3;
                    next_int_vector = vector_lut[3];
                    next_active_irqs[3] = 1'b1;
                    next_pending_irqs[3] = 1'b0;
                end else if (next_pending_irqs[2]) begin
                    next_current_irq = 3'd2;
                    next_int_vector = vector_lut[2];
                    next_active_irqs[2] = 1'b1;
                    next_pending_irqs[2] = 1'b0;
                end else if (next_pending_irqs[1]) begin
                    next_current_irq = 3'd1;
                    next_int_vector = vector_lut[1];
                    next_active_irqs[1] = 1'b1;
                    next_pending_irqs[1] = 1'b0;
                end else if (next_pending_irqs[0]) begin
                    next_current_irq = 3'd0;
                    next_int_vector = vector_lut[0];
                    next_active_irqs[0] = 1'b1;
                    next_pending_irqs[0] = 1'b0;
                end
                // If |next_pending_irqs is true, one of the above branches will be taken.
            end

            // Update registers with calculated next states
            active_irqs <= next_active_irqs;
            pending_irqs <= next_pending_irqs;
            int_active <= next_int_active;
            current_irq <= next_current_irq;
            int_vector <= next_int_vector;
        end
    end
endmodule