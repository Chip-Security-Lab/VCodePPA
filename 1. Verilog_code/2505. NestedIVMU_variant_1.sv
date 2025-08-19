//SystemVerilog
// SystemVerilog
//-----------------------------------------------------------------------------
// Module: ivmu_ret_stack
// Description: Manages the return address stack and stack pointer.
// Handles push and pop operations for interrupt context saving/restoring.
//-----------------------------------------------------------------------------
module ivmu_ret_stack (
    input wire clk,         // Clock signal
    input wire rst_n,       // Asynchronous reset, active low
    input wire push,        // Push enable (level-sensitive)
    input wire pop,         // Pop enable (level-sensitive)
    input wire [31:0] push_data, // Data to push onto the stack
    output wire [31:0] pop_data,  // Data popped from the stack (combinational read)
    output wire [1:0] ptr         // Current stack pointer value (registered)
);

    // Internal stack memory (4 deep, 32-bit data)
    // Memory is typically implemented using registers or dedicated block RAMs
    reg [31:0] stack [0:3];
    // Stack pointer register
    reg [1:0] stack_ptr_reg;

    // Stack pointer and memory write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset stack pointer to empty
            stack_ptr_reg <= 0;
            // Stack contents are typically undefined on reset, but can be initialized if needed
            // for (int i = 0; i < 4; i++) stack[i] <= 32'h0; // Optional: initialize stack content
        end else begin
            if (push && stack_ptr_reg < 4) begin
                // Push operation: store data and increment pointer
                stack[stack_ptr_reg] <= push_data;
                stack_ptr_reg <= stack_ptr_reg + 1;
            end else if (pop && stack_ptr_reg > 0) begin
                // Pop operation: decrement pointer
                stack_ptr_reg <= stack_ptr_reg - 1;
            end
            // If both push and pop are asserted, behavior is undefined/depends on synthesis tool.
            // Assuming mutual exclusion or priority handled by calling module.
        end
    end

    // Combinational read from the stack
    // Reads the element that is currently at the top of the stack (pointed to by ptr-1)
    // This is the value that will be returned on a pop operation.
    // Accessing memory combinatorially based on a register (stack_ptr_reg)
    assign pop_data = (stack_ptr_reg > 0) ? stack[stack_ptr_reg - 1] : 32'h0; // Return 0 if stack is empty

    // Output the current stack pointer (registered output)
    assign ptr = stack_ptr_reg;

endmodule

//-----------------------------------------------------------------------------
// Module: ivmu_irq_arbiter
// Description: Determines the highest priority pending interrupt
// that is higher than the current priority level.
//-----------------------------------------------------------------------------
module ivmu_irq_arbiter (
    input wire [3:0] irq,             // Input interrupt requests (level 3 is highest)
    input wire [3:0] current_pri_level, // Current active priority level
    output reg [3:0] highest_irq_idx,   // Index of the highest pending interrupt (combinational)
    output reg irq_take_request       // Flag indicating if a higher priority IRQ is pending (combinational)
);

    integer i; // Loop variable

    // Combinational logic to find the highest priority pending IRQ
    always @(*) begin
        highest_irq_idx = 4'h0; // Default to level 0
        irq_take_request = 0;  // Default to no request

        // Iterate from highest priority (3) down to lowest (0)
        for (i = 3; i >= 0; i = i - 1) begin
            // Check if IRQ is active AND its priority is higher than the current level
            if (irq[i] && i > current_pri_level) begin
                highest_irq_idx = i;      // Found the highest priority IRQ to take
                irq_take_request = 1;     // Signal that an IRQ should be taken
                // Exit loop once the highest priority is found
                i = -1; // Break condition for integer loop
            end
        end
    end

endmodule

//-----------------------------------------------------------------------------
// Module: NestedIVMU
// Description: Top-level module for the Interrupt Vector Management Unit (IVMU).
// Orchestrates interrupt handling, context stacking, and vector address generation.
// Instantiates stack and arbiter submodules.
// Applies retiming by registering inputs to the main control logic.
//-----------------------------------------------------------------------------
module NestedIVMU (
    input wire clk,         // Clock signal
    input wire rst_n,       // Asynchronous reset, active low
    input wire [3:0] irq,   // Input interrupt requests (level 3 is highest)
    input wire ack,         // Interrupt acknowledge signal
    input wire ret,         // Return from interrupt signal
    output reg [31:0] vec_addr,  // Output vector address (registered)
    output reg irq_active        // Output flag indicating if an interrupt context is active (registered)
);

    // Internal state registers
    reg [3:0] pri_level;     // Current active priority level
    reg [3:0] active_irqs;   // Tracks which IRQ levels have active contexts on the stack

    // Vector table storage (kept in top module for simple initialization)
    reg [31:0] vec_table [0:3];
    integer j; // Loop variable for initial block

    // Initialize vector table
    initial begin
        for (j = 0; j < 4; j = j + 1)
            vec_table[j] = 32'h4000_0000 + (j << 4); // Example base addresses
    end

    // --- Retiming: Register inputs and submodule outputs before main control logic ---
    reg ret_r;
    reg ack_r;
    // irq is fed directly to the combinational arbiter, its effect is delayed by registering arbiter outputs

    // Wires for connecting to submodules (combinational outputs)
    wire [31:0] stack_pop_data_comb;  // Data popped from the stack (combinational read)
    wire [1:0] stack_ptr;             // Current stack pointer from stack module (registered)
    wire [3:0] arbiter_highest_irq_idx_comb; // Highest priority IRQ index from arbiter (combinational)
    wire arbiter_irq_take_request_comb;    // Flag from arbiter indicating IRQ needs handling (combinational)

    // Registered versions of submodule outputs
    reg [31:0] stack_pop_data_r;
    reg [3:0] arbiter_highest_irq_idx_r;
    reg arbiter_irq_take_request_r;

    // Register inputs and submodule outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ret_r <= 1'b0;
            ack_r <= 1'b0;
            stack_pop_data_r <= 32'h0;
            arbiter_highest_irq_idx_r <= 4'h0;
            arbiter_irq_take_request_r <= 1'b0;
        end else begin
            ret_r <= ret;
            ack_r <= ack;
            stack_pop_data_r <= stack_pop_data_comb;
            arbiter_highest_irq_idx_r <= arbiter_highest_irq_idx_comb;
            arbiter_irq_take_request_r <= arbiter_irq_take_request_comb;
        end
    end
    // --- End Retiming Registers ---


    // Signals for driving submodule inputs (combinational, based on registered signals)
    wire stack_push;            // Signal to push onto the stack
    wire stack_pop;             // Signal to pop from the stack
    wire [31:0] stack_push_data; // Data to push onto the stack

    // Instantiate Stack Module
    ivmu_ret_stack u_ret_stack (
        .clk(clk),
        .rst_n(rst_n),
        .push(stack_push),
        .pop(stack_pop),
        .push_data(stack_push_data),
        .pop_data(stack_pop_data_comb), // Connect combinational output wire
        .ptr(stack_ptr) // Connect registered output wire
    );

    // Instantiate Arbiter Module
    ivmu_irq_arbiter u_irq_arbiter (
        .irq(irq), // irq input is not registered at this level
        .current_pri_level(pri_level), // pri_level is a state register
        .highest_irq_idx(arbiter_highest_irq_idx_comb), // Connect combinational output wire
        .irq_take_request(arbiter_irq_take_request_comb) // Connect combinational output wire
    );

    // Control Logic (State Machine)
    // Determines state transitions and drives submodule control signals
    // Uses registered inputs and registered submodule outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            pri_level <= 4'h0;
            active_irqs <= 4'h0;
            irq_active <= 1'b0;
            vec_addr <= 32'h0; // Reset vector address
        end else begin
            // Handle events based on priority: Return > Interrupt > Acknowledge
            // Use registered signals ret_r, ack_r, stack_pop_data_r,
            // arbiter_irq_take_request_r, arbiter_highest_irq_idx_r, stack_ptr (already reg)

            if (ret_r && stack_ptr > 2'b0) begin // Use ret_r, stack_ptr
                // Handle Return from Interrupt
                vec_addr <= stack_pop_data_r; // Use registered stack_pop_data
                // Restore priority level based on the context being returned to
                pri_level <= (stack_ptr > 2'b1) ? (stack_ptr - 2'b1) : 4'h0; // Use stack_ptr
                // irq_active remains high if there are still contexts on the stack after pop
                irq_active <= (stack_ptr > 2'b1); // Use stack_ptr

            end else if (arbiter_irq_take_request_r && stack_ptr < 2'b11) begin // Use arbiter_irq_take_request_r, stack_ptr
                // Handle Interrupt Request
                // A higher priority IRQ is pending and stack is not full
                vec_addr <= vec_table[arbiter_highest_irq_idx_r]; // Use registered arbiter_highest_irq_idx
                pri_level <= arbiter_highest_irq_idx_r;           // Use registered arbiter_highest_irq_idx
                irq_active <= 1'b1;                                // Indicate IRQ context is active
                active_irqs[arbiter_highest_irq_idx_r] <= 1'b1;      // Use registered arbiter_highest_irq_idx

            end else if (ack_r) begin // Use ack_r
                // Handle Interrupt Acknowledge
                // Clear the 'active' flag for the acknowledged interrupt level (current pri_level)
                active_irqs[pri_level] <= 1'b0; // Use pri_level (state register)
                // irq_active is cleared only when the last context on the stack is acknowledged.
                if (stack_ptr == 2'b01) begin // Use stack_ptr
                    irq_active <= 1'b0;
                end
            end
            // If none of the above conditions are met, state remains unchanged.
        end
    end

    // Combinational logic to drive stack control signals and push data
    // These now use the registered inputs/submodule outputs to align with the state machine's timing
    assign stack_push = (arbiter_irq_take_request_r && stack_ptr < 2'b11) && !(ret_r && stack_ptr > 2'b0);
    assign stack_pop = (ret_r && stack_ptr > 2'b0);
    assign stack_push_data = vec_addr; // vec_addr is a state register

endmodule