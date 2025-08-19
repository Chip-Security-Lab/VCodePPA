//SystemVerilog
module nested_icmu #(
    parameter NEST_LEVELS = 4,
    parameter WIDTH = 32
)(
    input clk, reset_n,
    input [WIDTH-1:0] irq,
    input [WIDTH*4-1:0] irq_priority_flat,
    input complete,
    output reg [4:0] active_irq,
    output reg [4:0] stack_ptr,
    output reg ctx_switch
);
    reg [4:0] irq_stack [0:NEST_LEVELS-1];
    reg [3:0] pri_stack [0:NEST_LEVELS-1];
    reg [3:0] current_priority;
    wire [3:0] irq_priority [0:WIDTH-1];
    integer i; // Used in both sequential and combinational blocks

    // From flat array extract priority
    genvar g;
    generate
        for (g = 0; g < WIDTH; g = g + 1) begin: prio_map
            assign irq_priority[g] = irq_priority_flat[g*4+3:g*4];
        end
    endgenerate

    // Combinational logic to find the highest priority pending IRQ > current_priority
    reg [4:0] best_irq_idx_comb;
    reg [3:0] best_irq_pri_comb;
    reg found_best_candidate_comb;

    wire [4:0] next_irq_idx = best_irq_idx_comb;
    wire [3:0] next_irq_pri = best_irq_pri_comb;
    wire found_candidate_irq = found_best_candidate_comb;

    always @(*) begin
        best_irq_idx_comb = 5'd32; // Default invalid index
        best_irq_pri_comb = 4'd0;  // Default to lowest priority
        found_best_candidate_comb = 1'b0;

        // Iterate from 0 to WIDTH-1 to find the highest priority candidate.
        // If multiple candidates have the same highest priority, this loop structure
        // naturally selects the one with the lowest index.
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (irq[i] && irq_priority[i] > current_priority) begin
                // Found a valid candidate
                if (!found_best_candidate_comb || irq_priority[i] > best_irq_pri_comb) begin
                    // This is the first valid candidate found OR it has a higher priority
                    best_irq_pri_comb = irq_priority[i];
                    best_irq_idx_comb = i[4:0];
                    found_best_candidate_comb = 1'b1;
                end
                // If irq_priority[i] == best_irq_pri_comb, the condition is false,
                // preserving the best_irq_idx_comb from the earlier index 'i' (lowest index tie-breaker).
            end
        end
    end

    // Sequential logic for state updates
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stack_ptr <= 5'd0;
            active_irq <= 5'd31; // 31 indicates no active IRQ (assuming WIDTH <= 32)
            current_priority <= 4'd0; // Priority 0 is the lowest
            ctx_switch <= 1'b0;

            // Initialize stack
            for (i = 0; i < NEST_LEVELS; i = i + 1) begin
                irq_stack[i] <= 5'd0;
                pri_stack[i] <= 4'd0;
            end
        end else begin
            ctx_switch <= 1'b0; // Default to no context switch this cycle

            // --- Handle interrupt completion (Pop) ---
            // Check complete and stack_ptr > 0 using the value *before* decrement
            if (complete && stack_ptr > 0) begin
                stack_ptr <= stack_ptr - 1'b1;
                // Determine next active IRQ based on the stack state *after* decrement.
                // The new stack pointer will be original_stack_ptr - 1.
                // The element at the new top is at index (original_stack_ptr - 1) - 1 = original_stack_ptr - 2.
                // Access the stack using the original_stack_ptr value.
                if (stack_ptr >= 2) begin // Check if there's an element below the one being popped
                    active_irq <= irq_stack[stack_ptr-2];
                    current_priority <= pri_stack[stack_ptr-2];
                end else begin // Original stack_ptr was 0 or 1. New stack_ptr will be -1 or 0. Stack is empty.
                    active_irq <= 5'd31; // No active interrupt
                    current_priority <= 4'd0;
                end
                ctx_switch <= 1'b1; // Signal context switch due to pop
            end

            // --- Handle new higher priority interrupt (Push) ---
            // This happens only if no pop occurred this cycle (`!ctx_switch` from the pop logic)
            // AND a suitable candidate was found combinatorially (`found_candidate_irq`)
            // AND the stack is not full (`stack_ptr < NEST_LEVELS`)
            if (!ctx_switch) begin // Check if pop occurred in this cycle
                if (found_candidate_irq && stack_ptr < NEST_LEVELS) begin
                    // Push the new interrupt context onto the stack
                    irq_stack[stack_ptr] <= next_irq_idx;
                    pri_stack[stack_ptr] <= next_irq_pri;
                    stack_ptr <= stack_ptr + 1'b1;
                    active_irq <= next_irq_idx; // New interrupt becomes active
                    current_priority <= next_irq_pri;
                    ctx_switch <= 1'b1; // Signal context switch due to push
                end
            end
        end
    end

endmodule