//SystemVerilog
//------------------------------------------------------------------------------
// Top-level nested_icmu Module
// Integrates priority decoding, arbitration, and stack management
//------------------------------------------------------------------------------
module nested_icmu #(
    parameter NEST_LEVELS = 4,
    parameter WIDTH = 32
)(
    input clk,
    input reset_n,
    input [WIDTH-1:0] irq,
    input [WIDTH*4-1:0] irq_priority_flat,
    input complete,

    output [4:0] active_irq,
    output [4:0] stack_ptr,
    output ctx_switch
);

    // Internal signals connecting submodules
    wire [WIDTH-1:0][3:0] irq_priority;
    wire [3:0] current_priority; // From stack manager
    wire found_high_pri_irq; // From arbiter
    wire [4:0] selected_irq_idx; // From arbiter
    wire [3:0] selected_irq_pri; // From arbiter
    wire stack_full; // Derived from stack_ptr

    // Instantiate Priority Decoder
    priority_decoder #(
        .WIDTH(WIDTH)
    ) u_priority_decoder (
        .irq_priority_flat(irq_priority_flat),
        .irq_priority(irq_priority)
    );

    // Instantiate Stack Manager (handles sequential logic and state)
    // Note: stack_full is now an input to stack_manager, derived here
    stack_manager #(
        .NEST_LEVELS(NEST_LEVELS)
    ) u_stack_manager (
        .clk(clk),
        .reset_n(reset_n),
        .complete(complete),
        .found_high_pri_irq(found_high_pri_irq),
        .selected_irq_idx(selected_irq_idx),
        .selected_irq_pri(selected_irq_pri),
        .stack_full(stack_full), // Connect derived signal

        .active_irq(active_irq),
        .stack_ptr(stack_ptr),
        .ctx_switch(ctx_switch),
        .current_priority(current_priority) // Output current priority
    );

    // Derive stack_full signal based on stack_ptr from stack_manager
    // This wire is read by the interrupt_arbiter and the stack_manager.
    assign stack_full = (stack_ptr == NEST_LEVELS);

    // Instantiate Interrupt Arbiter (handles combinational logic)
    interrupt_arbiter #(
        .WIDTH(WIDTH)
    ) u_interrupt_arbiter (
        .irq(irq),
        .irq_priority(irq_priority),
        .current_priority(current_priority), // Input current priority from stack_manager
        .stack_full(stack_full), // Input stack full status

        .found_high_pri_irq(found_high_pri_irq),
        .selected_irq_idx(selected_irq_idx),
        .selected_irq_pri(selected_irq_pri)
    );

endmodule

//------------------------------------------------------------------------------
// priority_decoder Module
// Decodes flat priority array into indexed array
//------------------------------------------------------------------------------
module priority_decoder #(
    parameter WIDTH = 32
)(
    input [WIDTH*4-1:0] irq_priority_flat,
    output [WIDTH-1:0][3:0] irq_priority
);

    genvar g;
    generate
        for (g = 0; g < WIDTH; g = g + 1) begin: prio_map
            assign irq_priority[g] = irq_priority_flat[g*4+3:g*4];
        end
    endgenerate

endmodule

//------------------------------------------------------------------------------
// interrupt_arbiter Module
// Finds the highest priority pending IRQ above current level
//------------------------------------------------------------------------------
module interrupt_arbiter #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] irq,
    input [WIDTH-1:0][3:0] irq_priority,
    input [3:0] current_priority,
    input stack_full, // Indicate if stack is full

    output reg found_high_pri_irq,
    output reg [4:0] selected_irq_idx,
    output reg [3:0] selected_irq_pri
);

    integer i;
    reg [4:0] found_idx;
    reg [3:0] found_pri;
    reg found;

    // This combinational block finds the highest priority pending IRQ.
    // Splitting this into multiple always @(*) blocks is not standard practice
    // and is unlikely to improve PPA or clarity for this specific logic.
    // Keeping it as a single block allows the synthesis tool to optimize it holistically.
    // The logic iterates through IRQs, prioritizing higher priority and then lower index.
    always @(*) begin
        found = 1'b0;
        found_idx = 5'd31; // Default to invalid index
        found_pri = 4'd0;

        // Iterate through IRQs to find the highest priority pending IRQ
        // that is higher than the current priority and stack is not full.
        // This is a combinational loop, prioritizing lower index in case of equal priority.
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (irq[i] && irq_priority[i] > current_priority && !stack_full) begin
                // Found a candidate. If this is the first one found, or if its priority
                // is higher than the current best candidate, or if priorities are equal
                // but this index is lower, update the best candidate.
                // The condition `!found || irq_priority[i] > found_pri` ensures
                // higher priority is always preferred. If priorities are equal,
                // the first one found (lowest index) is kept because `irq_priority[i] > found_pri`
                // will be false, and the update only happens if `!found`.
                if (!found || irq_priority[i] > found_pri) begin
                    found = 1'b1;
                    found_idx = i[4:0];
                    found_pri = irq_priority[i];
                end
            end
        end

        // Assign results to outputs
        found_high_pri_irq = found;
        selected_irq_idx = found_idx;
        selected_irq_pri = found_pri;
    end

endmodule

//------------------------------------------------------------------------------
// stack_manager Module
// Manages the IRQ stack, stack pointer, active IRQ, and context switch
// Refactored into multiple always blocks and using case statements
//------------------------------------------------------------------------------
module stack_manager #(
    parameter NEST_LEVELS = 4
)(
    input clk,
    input reset_n,
    input complete, // Current IRQ handler complete
    input found_high_pri_irq, // Arbiter found a higher priority IRQ
    input [4:0] selected_irq_idx, // Index of selected IRQ from arbiter
    input [3:0] selected_irq_pri, // Priority of selected IRQ from arbiter
    input stack_full, // Indicate if stack is full (derived from stack_ptr in top module)

    output reg [4:0] active_irq,
    output reg [4:0] stack_ptr,
    output reg ctx_switch,
    output reg [3:0] current_priority // Output current priority for arbiter
);

    reg [4:0] irq_stack [0:NEST_LEVELS-1];
    reg [3:0] pri_stack [0:NEST_LEVELS-1];

    integer i; // Used in reset loop

    // Combinational logic to determine next stack pointer action
    reg [1:0] next_ptr_ctrl;
    always @(*) begin
        next_ptr_ctrl = 2'b00; // Default: Hold
        if (complete && stack_ptr > 0) begin
            next_ptr_ctrl = 2'b01; // Pop
        end else if (found_high_pri_irq && !complete && !stack_full) begin
            next_ptr_ctrl = 2'b10; // Push
        end
    end

    // Block 1: Stack Pointer Update (Sequential)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stack_ptr <= 5'd0;
        end else begin
            case (next_ptr_ctrl)
                2'b01: stack_ptr <= stack_ptr - 1'b1; // Pop
                2'b10: stack_ptr <= stack_ptr + 1'b1; // Push
                default: stack_ptr <= stack_ptr;     // Hold (2'b00)
            endcase
        end
    end

    // Block 2: Stack Data (irq_stack, pri_stack) Update (Sequential)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Initialize stack data
            for (i = 0; i < NEST_LEVELS; i = i + 1) begin
                irq_stack[i] <= 5'd0;
                pri_stack[i] <= 4'd0;
            end
        end else begin
            case (next_ptr_ctrl)
                2'b10: begin // Push
                    irq_stack[stack_ptr] <= selected_irq_idx;
                    pri_stack[stack_ptr] <= selected_irq_pri;
                end
                // 2'b01 (Pop) and 2'b00 (Hold) result in no change to stack data
                // Default case handles hold implicitly for registers
            endcase
        end
    end

    // Combinational logic to determine next active IRQ/priority state
    reg [1:0] next_ctx_ctrl;
    always @(*) begin
        next_ctx_ctrl = 2'b00; // Default: Hold
        if (complete && stack_ptr > 0) begin
            if (stack_ptr == 1) begin // stack_ptr > 0 && stack_ptr == 1 -> stack_ptr == 1
                next_ctx_ctrl = 2'b01; // Pop to empty
            end else begin // stack_ptr > 0 && stack_ptr > 1 -> stack_ptr > 1
                next_ctx_ctrl = 2'b10; // Pop to non-empty
            end
        end else if (found_high_pri_irq && !complete && !stack_full) begin
            next_ctx_ctrl = 2'b11; // Push
        end
    end

    // Block 3: Active IRQ and Current Priority Update (Sequential)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            active_irq <= 5'd31; // 31 indicates no active IRQ (assuming WIDTH <= 32)
            current_priority <= 4'd0;
        end else begin
            case (next_ctx_ctrl)
                2'b01: begin // Pop to empty
                    active_irq <= 5'd31;
                    current_priority <= 4'd0;
                end
                2'b10: begin // Pop to non-empty
                    active_irq <= irq_stack[stack_ptr-2];
                    current_priority <= pri_stack[stack_ptr-2];
                end
                2'b11: begin // Push
                    active_irq <= selected_irq_idx;
                    current_priority <= selected_irq_pri;
                end
                default: begin // Hold (2'b00)
                    active_irq <= active_irq;
                    current_priority <= current_priority;
                end
            endcase
        end
    end

    // Block 4: Context Switch Flag Update (Sequential)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ctx_switch <= 1'b0;
        end else begin
            // Context switch occurs if an action (Pop or Push) happens.
            // This is indicated by next_ctx_ctrl not being the 'Hold' state (2'b00).
            ctx_switch <= (next_ctx_ctrl != 2'b00);
        end
    end

endmodule