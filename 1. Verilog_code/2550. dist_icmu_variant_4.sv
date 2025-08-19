//SystemVerilog
module dist_icmu (
    input wire core_clk,
    input wire [3:0] local_int_req,
    input wire [1:0] remote_int_req,
    input wire [31:0] cpu_ctx,
    output wire [31:0] saved_ctx,
    output wire [2:0] int_src,
    output wire int_valid,
    output wire local_ack,
    output wire [1:0] remote_ack
);

    localparam LOCAL_BASE = 0;
    localparam REMOTE_BASE = 4;

    // State machine for pipelined handling (3 stages + IDLE)
    parameter STATE_IDLE          = 3'b000; // Waiting for interrupts
    parameter STATE_CALC_PRIORITY = 3'b001; // Stage 1: Determine priority and raw source ID
    parameter STATE_CALC_MASKS    = 3'b010; // Stage 2: Calculate masks based on stage 1 results
    parameter STATE_ISSUE         = 3'b011; // Stage 3: Issue interrupt outputs and update state

    reg [2:0] state_reg, next_state;

    // Internal state registers
    reg [5:0] pending = 6'b0; // Tracks pending interrupts (local 3:0, remote 5:4)
    reg [5:0] active = 6'b0;  // Indicates which interrupt is currently being handled

    // Pipeline registers (Stage 1 results - Priority and Source ID)
    reg pipe1_is_remote;
    reg [2:0] pipe1_int_src;
    reg [5:0] pipe1_pending; // Latch pending state at the start of Stage 1

    // Pipeline registers (Stage 2 results - Masks and Context)
    reg [31:0] pipe2_saved_ctx;
    reg [2:0] pipe2_int_src;
    reg pipe2_is_remote;
    reg [3:0] pipe2_local_pending_clear_mask; // Mask to clear specific local pending bit
    reg [3:0] pipe2_local_active_set_mask;  // Mask to set specific local active bit
    reg [1:0] pipe2_remote_pending_clear_mask; // Mask to clear remote pending bits
    reg [1:0] pipe2_remote_active_set_mask;  // Mask to set remote active bits
    reg pipe2_local_ack_set_mask;           // Mask for local ack output (single bit)
    reg [1:0] pipe2_remote_ack_set_mask;      // Mask for remote ack output (2 bits)

    // Registered outputs (Stage 3 results)
    reg [31:0] saved_ctx_reg;
    reg [2:0] int_src_reg;
    reg int_valid_reg;
    reg local_ack_reg;
    reg [1:0] remote_ack_reg;

    // Assign registered outputs to module outputs
    assign saved_ctx = saved_ctx_reg;
    assign int_src = int_src_reg;
    assign int_valid = int_valid_reg;
    assign local_ack = local_ack_reg;
    assign remote_ack = remote_ack_reg;

    // State and pipeline registers update
    always @(posedge core_clk) begin
        // Update state register
        state_reg <= next_state;

        // Update pending based on inputs (continuous)
        pending[3:0] <= pending[3:0] | local_int_req;
        pending[5:4] <= pending[5:4] | remote_int_req;

        // --- Pipeline Stage 1: Calculate Priority and Source ID ---
        if (next_state == STATE_CALC_PRIORITY) begin
            reg calculated_pipe1_is_remote;
            reg [2:0] calculated_pipe1_int_src;

            // Determine priority and calculate source based on current pending state
            if (|pending[5:4]) begin
                // Remote interrupts have higher priority
                calculated_pipe1_is_remote = 1'b1;
                calculated_pipe1_int_src = get_src(pending[5:4], REMOTE_BASE);
            end else begin
                // Handle local interrupts
                calculated_pipe1_is_remote = 1'b0;
                calculated_pipe1_int_src = get_src(pending[3:0], LOCAL_BASE);
            end

            // Latch results into pipe1 registers
            pipe1_is_remote <= calculated_pipe1_is_remote;
            pipe1_int_src <= calculated_pipe1_int_src;
            pipe1_pending <= pending; // Latch pending state for Stage 2 mask calculation
        end

        // --- Pipeline Stage 2: Calculate Masks and Latch Context ---
        if (next_state == STATE_CALC_MASKS) begin
            reg [3:0] calculated_pipe2_local_pending_clear_mask;
            reg [3:0] calculated_pipe2_local_active_set_mask;
            reg [1:0] calculated_pipe2_remote_pending_clear_mask;
            reg [1:0] calculated_pipe2_remote_active_set_mask;
            reg calculated_pipe2_local_ack_set_mask;
            reg [1:0] calculated_pipe2_remote_ack_set_mask;

            // Default mask values
            calculated_pipe2_local_pending_clear_mask = 4'b0;
            calculated_pipe2_local_active_set_mask = 4'b0;
            calculated_pipe2_remote_pending_clear_mask = 2'b00;
            calculated_pipe2_remote_active_set_mask = 2'b00;
            calculated_pipe2_local_ack_set_mask = 1'b0;
            calculated_pipe2_remote_ack_set_mask = 2'b00;

            // Calculate masks based on pipe1 results (latched priority and source)
            if (pipe1_is_remote) begin
                // Masks for remote interrupt based on latched pending
                calculated_pipe2_remote_ack_set_mask = pipe1_pending[5:4];
                calculated_pipe2_remote_active_set_mask = pipe1_pending[5:4];
                calculated_pipe2_remote_pending_clear_mask = 2'b00; // Clear all remote pending bits
            end else begin
                // Masks for local interrupt based on latched source ID
                calculated_pipe2_local_ack_set_mask = 1'b1 << pipe1_int_src[1:0];
                calculated_pipe2_local_active_set_mask = 1'b1 << pipe1_int_src[1:0];
                calculated_pipe2_local_pending_clear_mask = 1'b1 << pipe1_int_src[1:0]; // Mask for clearing specific bit
            end

            // Latch results into pipe2 registers
            pipe2_int_src <= pipe1_int_src; // Pass source ID
            pipe2_is_remote <= pipe1_is_remote; // Pass remote flag
            pipe2_saved_ctx <= cpu_ctx; // Latch CPU context

            pipe2_local_pending_clear_mask <= calculated_pipe2_local_pending_clear_mask;
            pipe2_local_active_set_mask <= calculated_pipe2_local_active_set_mask;
            pipe2_remote_pending_clear_mask <= calculated_pipe2_remote_pending_clear_mask;
            pipe2_remote_active_set_mask <= calculated_pipe2_remote_active_set_mask;
            pipe2_local_ack_set_mask <= calculated_pipe2_local_ack_set_mask;
            pipe2_remote_ack_set_mask <= calculated_pipe2_remote_ack_set_mask;
        end

        // --- Pipeline Stage 3: Issue Outputs and Update State ---
        if (next_state == STATE_ISSUE) begin
            // Update active based on pipe2 masks
            if (pipe2_is_remote) begin
                 active[5:4] <= pipe2_remote_active_set_mask;
                 active[3:0] <= 4'b0000; // Clear local active when remote is handled
            end else begin
                 active[5:4] <= 2'b00; // Clear remote active when local is handled
                 active[3:0] <= pipe2_local_active_set_mask;
            end

            // Update pending based on pipe2 clear info
            if (pipe2_is_remote) begin
                pending[5:4] <= pipe2_remote_pending_clear_mask; // This is 2'b00
            end else begin
                // Clear the specific local bit using pipe2 mask and current pending
                pending[3:0] <= pending[3:0] & ~pipe2_local_pending_clear_mask;
            end

            // Update registered outputs based on pipe2 results
            int_valid_reg <= 1'b1;
            int_src_reg <= pipe2_int_src;
            saved_ctx_reg <= pipe2_saved_ctx;
            local_ack_reg <= pipe2_local_ack_set_mask;
            remote_ack_reg <= pipe2_remote_ack_set_mask;

        end else begin
            // Default/clear outputs and active when not in STATE_ISSUE
            int_valid_reg <= 1'b0;
            local_ack_reg <= 1'b0;
            remote_ack_reg <= 2'b00;
            // Set int_src and saved_ctx to default/don't care when not valid
            int_src_reg <= {3{1'b0}}; // Or 3'bxxx
            saved_ctx_reg <= {32{1'b0}}; // Or 32'bxxx

            // Active is cleared when handling finishes (returning to IDLE)
            active <= 6'b0;
        end
    end

    // Combinational next state logic
    always @* begin
        next_state = state_reg; // Default: stay in current state

        case (state_reg)
            STATE_IDLE: begin
                // Only move if there are pending interrupts
                if (|pending) begin
                    next_state = STATE_CALC_PRIORITY;
                end else begin
                    next_state = STATE_IDLE;
                end
            end

            STATE_CALC_PRIORITY: begin
                // Always move to the next stage after calculation
                next_state = STATE_CALC_MASKS;
            end

            STATE_CALC_MASKS: begin
                // Always move to the next stage after mask calculation
                next_state = STATE_ISSUE;
            end

            STATE_ISSUE: begin
                // Done issuing, go back to idle to check for next interrupt
                next_state = STATE_IDLE;
            end

            default: begin
                // Should not happen, reset to IDLE
                next_state = STATE_IDLE;
            end
        endcase
    end

    // Function to get interrupt source ID (combinational)
    // This function is used in STATE_CALC_PRIORITY
    function [2:0] get_src;
        input [3:0] src_bits; // Either pending[3:0] or pending[5:4] (zero-extended)
        input [2:0] base;     // Either LOCAL_BASE or REMOTE_BASE
        begin
            // Priority encoder logic using if-else if for optimized comparison chain
            if (src_bits[0]) begin
                get_src = base;
            end else if (src_bits[1]) begin
                get_src = base + 1;
            end else if (src_bits[2]) begin
                get_src = base + 2;
            end else if (src_bits[3]) begin
                get_src = base + 3;
            end else begin
                // Fallback if src_bits is 0. Should not be reached in this module's usage.
                get_src = base;
            end
        end
    endfunction

endmodule