//SystemVerilog
module nested_icmu #(
    parameter NEST_LEVELS = 4,
    parameter WIDTH = 32
)(
    input clk, reset_n,
    input [WIDTH-1:0] irq,
    input [WIDTH*4-1:0] irq_priority_flat, // Modified to flat array
    input complete,
    output reg [4:0] active_irq,
    output reg [4:0] stack_ptr,
    output reg ctx_switch
);
    // Stack to store interrupted context (IRQ index and priority)
    reg [4:0] irq_stack [0:NEST_LEVELS-1];
    reg [3:0] pri_stack [0:NEST_LEVELS-1];

    // State registers
    reg [3:0] current_priority; // Priority of the currently active IRQ
    // active_irq and stack_ptr are outputs, declared as reg

    // Internal variables
    integer i; // For initialization loops

    // Map flat priority array to indexed array
    wire [3:0] irq_priority [0:WIDTH-1];
    genvar g;
    generate
        for (g = 0; g < WIDTH; g = g + 1) begin: prio_map
            assign irq_priority[g] = irq_priority_flat[g*4+3:g*4];
        end
    endgenerate

    // Combinational logic to find the lowest index IRQ with higher priority
    // This logic replaces the sequential while loop in the original code
    logic [4:0] found_lowest_idx;
    logic [3:0] found_lowest_prio;
    logic found_higher_prio_candidate;

    // This always_comb block synthesizes into a priority encoder structure
    // It finds the lowest index 'k' such that irq[k] is high and irq_priority[k] > current_priority
    always_comb begin
        found_lowest_idx = 5'd31; // Default to invalid index (e.g., 31 if WIDTH <= 32)
        found_lowest_prio = 4'd0; // Default priority (value doesn't matter if flag is 0)
        found_higher_prio_candidate = 1'b0; // Default to no candidate found

        // Iterate from lowest index to highest. The first one meeting the criteria wins.
        for (int k = 0; k < WIDTH; k = k + 1) begin
            // Check if this IRQ is active, has higher priority than current,
            // AND we haven't found a lower index one yet.
            if (irq[k] && irq_priority[k] > current_priority && !found_higher_prio_candidate) begin
                found_lowest_idx = k[4:0]; // Capture the index
                found_lowest_prio = irq_priority[k]; // Capture the priority
                found_higher_prio_candidate = 1'b1; // Mark that a candidate is found
            end
        end
    end


    // Synchronous block for state updates
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset state
            stack_ptr <= 5'd0;
            active_irq <= 5'd31; // 31 indicates no active IRQ (assuming 0-30 are valid indices)
            current_priority <= 4'd0; // Lowest possible priority
            ctx_switch <= 1'b0;

            // Initialize stack contents (optional, but good practice)
            i = 0;
            while (i < NEST_LEVELS) begin
                irq_stack[i] <= 5'd0; // Default IRQ index
                pri_stack[i] <= 4'd0; // Default priority
                i = i + 1;
            end
        end else begin
            // Default ctx_switch to 0 for the current cycle
            ctx_switch <= 1'b0;

            // Logic for handling IRQ completion
            if (complete && stack_ptr > 0) begin
                reg [4:0] next_stack_ptr = stack_ptr - 1'b1; // Calculate the stack pointer value for the next cycle
                stack_ptr <= next_stack_ptr; // Update stack pointer
                if (next_stack_ptr > 0) begin // If stack is not empty after pop
                    // Restore context from the new top of stack (index next_stack_ptr - 1)
                    active_irq <= irq_stack[next_stack_ptr-1];
                    current_priority <= pri_stack[next_stack_ptr-1];
                end else begin
                    // Stack is now empty
                    active_irq <= 5'd31; // No active IRQ
                    current_priority <= 4'd0; // Lowest priority
                end
                ctx_switch <= 1'b1; // Context switch occurred due to completion
            end

            // Logic for handling new higher priority IRQ
            // Only check for a new IRQ if no context switch was already triggered by completion in this cycle
            // This ensures completion takes precedence over new IRQ in the same cycle
            if (!ctx_switch) begin
                // Check if the combinational logic found a higher priority candidate
                // AND there is space available on the stack to push the current context
                if (found_higher_prio_candidate && stack_ptr < NEST_LEVELS) begin
                    // Push the new context onto the stack at the current stack_ptr index
                    irq_stack[stack_ptr] <= found_lowest_idx;
                    pri_stack[stack_ptr] <= found_lowest_prio;
                    // Increment stack pointer for the next push
                    stack_ptr <= stack_ptr + 1'b1;
                    // Update active IRQ and current priority to the new, higher priority IRQ
                    active_irq <= found_lowest_idx;
                    current_priority <= found_lowest_prio;
                    // Context switch occurred due to a new higher priority IRQ
                    ctx_switch <= 1'b1;
                end
            end
        end
    end

endmodule