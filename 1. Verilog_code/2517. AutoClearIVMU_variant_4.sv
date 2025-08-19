//SystemVerilog
module AutoClearIVMU (
    input clk, rstn,
    input [7:0] irq_in,
    input service_done,
    output reg [31:0] int_vector,
    output reg int_active
);
    reg [31:0] vector_lut [0:7];
    reg [7:0] active_irqs;
    reg [7:0] pending_irqs;
    reg [2:0] current_irq;
    integer i;

    // Combinatorial logic to find the highest priority pending IRQ
    reg [2:0] highest_pending_idx_comb;
    reg found_pending_comb;

    always @(*) begin
        highest_pending_idx_comb = 3'b0;
        found_pending_comb = 1'b0;
        // Iterate from highest priority (7) down to lowest (0)
        for (i = 7; i >= 0; i = i - 1) begin
            if (pending_irqs[i]) begin
                highest_pending_idx_comb = i[2:0];
                found_pending_comb = 1'b1;
                // Due to the loop structure, the last assignment (highest i) wins
            end
        end
    end

    // Buffer registers for the output of the priority encoder (existing)
    reg [2:0] highest_pending_idx_buf;
    reg found_pending_buf;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            highest_pending_idx_buf <= 3'b0;
            found_pending_buf <= 1'b0;
        end else begin
            highest_pending_idx_buf <= highest_pending_idx_comb;
            found_pending_buf <= found_pending_comb;
        end
    end

    // Buffer register for active_irqs_next (new buffer stage)
    reg [7:0] active_irqs_buf;

    initial begin
        for (i = 0; i < 8; i = i + 1)
            vector_lut[i] = 32'hF000_0000 + (i * 16);
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            active_irqs <= 8'h0;
            pending_irqs <= 8'h0;
            int_active <= 1'b0;
            current_irq <= 3'b0;
            int_vector <= 32'h0;
            active_irqs_buf <= 8'h0; // Reset the new buffer
        end else begin
            // Calculate pending_irqs for the next cycle, including new IRQs
            reg [7:0] pending_irqs_next = pending_irqs | irq_in;

            // Calculate next state values, starting with holding current state
            // active_irqs_next is calculated here based on current state and buffered inputs
            reg [7:0] active_irqs_next = active_irqs; // Initialize active_irqs_next
            reg [2:0] current_irq_next = current_irq;
            reg [31:0] int_vector_next = int_vector;
            reg int_active_next = int_active;
            reg [7:0] pending_irqs_update = pending_irqs_next; // Start with updated pending

            if (service_done) begin
                active_irqs_next[current_irq] = 1'b0;
                int_active_next = 1'b0;
                // pending_irqs_update remains pending_irqs_next
            end else if (!int_active && found_pending_buf) begin
                // Service the IRQ found in the previous cycle based on buffered result
                int_active_next = 1'b1;
                current_irq_next = highest_pending_idx_buf;
                int_vector_next = vector_lut[highest_pending_idx_buf];
                active_irqs_next[highest_pending_idx_buf] = 1'b1;
                // Clear the serviced bit from the pending_irqs value *before* it's registered
                pending_irqs_update[highest_pending_idx_buf] = 1'b0;
            end
            // else if (!int_active && !found_pending_buf) {
            //   No IRQ to service based on buffered state, state holds except for pending_irqs_next
            // }

            // Update buffer register for active_irqs_next
            active_irqs_buf <= active_irqs_next; // Register the calculated next value

            // Update state registers using buffered value for active_irqs
            // active_irqs <= active_irqs_next; // Original update
            active_irqs <= active_irqs_buf; // Use the buffered value (adds a cycle delay to this path)

            pending_irqs <= pending_irqs_update; // Use the value after potential clearing
            int_active <= int_active_next;
            current_irq <= current_irq_next;
            int_vector <= int_vector_next;
        end
    end
endmodule