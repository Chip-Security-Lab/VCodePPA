//SystemVerilog
// SystemVerilog
// Top module for the interrupt distribution and context saving unit.
// Orchestrates the priority encoder and controller submodules.
// This module provides a Req-Ack handshake interface for interrupt notification.
module dist_icmu (
    input wire core_clk,
    input wire [3:0] local_int_req,
    input wire [1:0] remote_int_req,
    input wire [31:0] cpu_ctx,
    input wire int_ack,             // Input: Acknowledge signal from the sink

    output wire [31:0] saved_ctx, // Saved CPU context upon interrupt
    output wire [2:0] int_src,     // Encoded source of the highest priority pending interrupt (0-5)
    output wire int_req,           // Output: Asserted when a new interrupt is requested (Req-Ack)
    output wire [3:0] local_ack,   // Per-source acknowledgement for local interrupts (pulsed when req goes high)
    output wire [1:0] remote_ack   // Per-source acknowledgement for remote interrupts (pulsed when req goes high)
);

    // Internal wires to connect submodules
    wire [5:0] pending_w;       // Pending state from controller to encoder
    wire [2:0] int_src_w;       // Source index from encoder to controller
    wire any_pending_w;     // Any pending flag from encoder to controller

    // Wires for signals coming from the controller's registered outputs
    wire [31:0] saved_ctx_w;
    wire [2:0] int_src_out_w;
    wire int_req_w;
    wire [3:0] local_ack_w;
    wire [1:0] remote_ack_w;


    // Instantiate Priority Encoder submodule
    // This module is purely combinational and determines the highest priority source.
    int_priority_encoder u_priority_encoder (
        .pending(pending_w),        // Input: Current pending interrupt state (6 bits)
        .int_src(int_src_w),        // Output: Highest priority source index (0-5)
        .any_pending(any_pending_w) // Output: Flag indicating if any interrupt is pending
    );

    // Instantiate Interrupt Controller submodule
    // This module manages state, handles interrupt sequencing, and generates outputs
    // using a Req-Ack handshake for the main interrupt notification.
    int_controller u_controller (
        .core_clk(core_clk),            // Input: System clock
        .local_int_req(local_int_req),  // Input: Local interrupt requests (4 bits)
        .remote_int_req(remote_int_req),// Input: Remote interrupt requests (2 bits)
        .cpu_ctx(cpu_ctx),              // Input: Current CPU context
        .int_src_in(int_src_w),         // Input: Highest priority source index from encoder
        .any_pending_in(any_pending_w), // Input: Any pending flag from encoder
        .int_ack(int_ack),              // Input: Acknowledge signal from the sink

        .saved_ctx(saved_ctx_w),        // Output: Saved CPU context (registered)
        .int_src(int_src_out_w),        // Output: Encoded source (registered)
        .int_req(int_req_w),            // Output: Interrupt request signal (registered)
        .local_ack(local_ack_w),        // Output: Local acknowledge signals (pulsed, registered)
        .remote_ack(remote_ack_w),      // Output: Remote acknowledge signals (pulsed, registered)
        .pending_out(pending_w)         // Output: Current pending interrupt state (for encoder)
    );

    // Connect the internal signals from the controller's registered outputs to the top-level outputs
    assign saved_ctx = saved_ctx_w;
    assign int_src = int_src_out_w;
    assign int_req = int_req_w;
    assign local_ack = local_ack_w;
    assign remote_ack = remote_ack_w;

endmodule


// int_priority_encoder module
// Takes the 6-bit combined pending state and outputs the index (0-5)
// of the highest priority pending interrupt, and a flag indicating if any
// interrupt is pending.
// Priority order: pending[5] > pending[4] > pending[3] > pending[2] > pending[1] > pending[0].
// The output int_src corresponds directly to the bit index.
module int_priority_encoder (
    input wire [5:0] pending,       // Input: Combined pending interrupt state
    output wire [2:0] int_src,      // Output: Index of the highest priority source (0-5)
    output wire any_pending         // Output: Flag indicating if any interrupt is pending
);

    // any_pending is high if any bit in the pending vector is high
    assign any_pending = |pending;

    // Combinational logic to determine the highest priority source index
    reg [2:0] int_src_reg;

    always @(*) begin
        if (pending[5])
            int_src_reg = 3'd5; // Remote source 1
        else if (pending[4])
            int_src_reg = 3'd4; // Remote source 0
        else if (pending[3])
            int_src_reg = 3'd3; // Local source 3
        else if (pending[2])
            int_src_reg = 3'd2; // Local source 2
        else if (pending[1])
            int_src_reg = 3'd1; // Local source 1
        else // Includes pending[0] and no pending cases
             int_src_reg = 3'd0; // Local source 0 or default
    end

    // Assign the determined source index to the output
    assign int_src = int_src_reg;

endmodule


// int_controller module
// This module contains the state registers (pending, active, requesting)
// and the main synchronous logic to process interrupts, update state,
// and generate output signals (req, saved_ctx, src, acks) using a Req-Ack handshake.
module int_controller (
    input wire core_clk,            // Input: System clock
    input wire [3:0] local_int_req,  // Input: Local interrupt requests
    input wire [1:0] remote_int_req,// Input: Remote interrupt requests
    input wire [31:0] cpu_ctx,      // Input: Current CPU context
    input wire [2:0] int_src_in,    // Input: Highest priority source index from encoder (combinational)
    input wire any_pending_in,  // Input: Flag indicating any interrupt is pending (combinational)
    input wire int_ack,          // Input: Acknowledge signal from the sink

    output wire [31:0] saved_ctx,    // Output: Saved CPU context (registered)
    output wire [2:0] int_src,      // Output: Encoded source (registered)
    output wire int_req,           // Output: Interrupt request signal (registered)
    output wire [3:0] local_ack,     // Output: Local acknowledge signals (pulsed, registered)
    output wire [1:0] remote_ack,    // Output: Remote acknowledge signals (pulsed, registered)
    output wire [5:0] pending_out   // Output: Current pending interrupt state (for encoder, wire)
);

    // Internal state registers
    reg [5:0] pending_r = 6'b0; // Tracks pending interrupt requests (0-3 local, 4-5 remote)
    reg requesting_r = 1'b0;    // State: Flag indicating if a request is currently asserted
    reg [5:0] active_r = 6'b0;  // State: Tracks which interrupt source is currently being requested

    // Registered outputs
    reg [31:0] saved_ctx_reg;
    reg [2:0] int_src_reg;
    reg int_req_reg = 1'b0;
    reg [3:0] local_ack_reg = 4'b0;
    reg [1:0] remote_ack_reg = 2'b0;

    // Assign internal registers to outputs
    assign pending_out = pending_r;
    assign saved_ctx = saved_ctx_reg;
    assign int_src = int_src_reg;
    assign int_req = int_req_reg;
    assign local_ack = local_ack_reg;
    assign remote_ack = remote_ack_reg;

    // Main synchronous logic: state updates and output generation
    always @(posedge core_clk) begin
        // Default assignments for next state and outputs
        reg [5:0] next_pending = pending_r;
        reg next_requesting = requesting_r;
        reg [5:0] next_active = active_r;
        reg [31:0] next_saved_ctx = saved_ctx_reg; // Retain previous saved context by default
        reg [2:0] next_int_src = int_src_reg;     // Retain previous source by default
        reg next_int_req = int_req_reg;           // Retain previous request state by default
        reg [3:0] next_local_ack = 4'b0;          // Acks are pulsed, default to 0
        reg [1:0] next_remote_ack = 2'b0;         // Acks are pulsed, default to 0


        // Update pending requests by ORing current pending state with new requests
        // This happens unconditionally every cycle
        next_pending[3:0] = pending_r[3:0] | local_int_req;
        next_pending[5:4] = pending_r[5:4] | remote_int_req;


        // State machine for Req-Ack handshake
        if (!requesting_r && any_pending_in) begin
            // State transition: IDLE to REQUESTING
            // A new interrupt is pending and the unit is not currently requesting.
            next_requesting = 1'b1;       // Enter requesting state
            next_int_req = 1'b1;          // Assert interrupt request signal

            next_saved_ctx = cpu_ctx;   // Sample current CPU context
            next_int_src = int_src_in;  // Sample the highest priority source index

            // Clear active state from previous handling cycle (if any) and set for current request
            next_active = 6'b0;
            next_active[int_src_in] = 1'b1; // Set the active bit corresponding to the selected source

            // Pulse the appropriate acknowledge signal for the source for one cycle
            case (int_src_in)
                3'd0: next_local_ack = 4'b0001; // Local 0
                3'd1: next_local_ack = 4'b0010; // Local 1
                3'd2: next_local_ack = 4'b0100; // Local 2
                3'd3: next_local_ack = 4'b1000; // Local 3
                3'd4: next_remote_ack = 2'b01; // Remote 0
                3'd5: next_remote_ack = 2'b10; // Remote 1
                default: begin
                    // Should not happen if encoder is correct
                end
            endcase

        end else if (requesting_r && int_ack) begin
            // State transition: REQUESTING to IDLE
            // The request was acknowledged by the sink.
            next_requesting = 1'b0;      // Exit requesting state
            next_active = 6'b0;          // Clear active state
            next_int_req = 1'b0;         // Deassert request

            // Clear the pending bit for the source that was active/requested
            // Use int_src_reg as active_r is being cleared in this cycle
            case (int_src_reg)
                3'd0: next_pending[0] = 1'b0;
                3'd1: next_pending[1] = 1'b0;
                3'd2: next_pending[2] = 1'b0;
                3'd3: next_pending[3] = 1'b0;
                3'd4: next_pending[4] = 1'b0;
                3'd5: next_pending[5] = 1'b0;
                default: begin
                    // Should not happen
                end
            endcase

            // next_saved_ctx and next_int_src retain values or could be reset
            // next_local_ack and next_remote_ack are already defaulted to 0

        end else if (requesting_r && !int_ack) begin
            // State: Stay in REQUESTING
            // Waiting for the acknowledge signal.
            next_requesting = 1'b1; // Stay in requesting state
            next_active = active_r; // Keep active source
            next_saved_ctx = saved_ctx_reg; // Keep data stable
            next_int_src = int_src_reg; // Keep data stable
            next_int_req = 1'b1; // Keep request high
            // next_local_ack and next_remote_ack are already defaulted to 0
        end
        // else (!requesting_r && !any_pending_in): Stay in IDLE state.
        // next_pending updates unconditionally above.
        // Other next state/output variables remain at their default values (retaining previous).


        // Update state registers and output registers with next state values
        pending_r <= next_pending;
        requesting_r <= next_requesting;
        active_r <= next_active;
        saved_ctx_reg <= next_saved_ctx;
        int_src_reg <= next_int_src;
        int_req_reg <= next_int_req;
        local_ack_reg <= next_local_ack;
        remote_ack_reg <= next_remote_ack;
    end

endmodule