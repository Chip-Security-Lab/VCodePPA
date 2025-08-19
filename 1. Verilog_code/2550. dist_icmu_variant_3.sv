//SystemVerilog
module dist_icmu (
    input wire core_clk,
    input wire [3:0] local_int_req,
    input wire [1:0] remote_int_req,
    input wire [31:0] cpu_ctx,
    output reg [31:0] saved_ctx,
    output reg [2:0] int_src,
    output reg int_valid,
    output reg [3:0] local_ack, // Corrected width based on assignment
    output reg [1:0] remote_ack
);
    localparam LOCAL_BASE = 3'd0; // Keep for context
    localparam REMOTE_BASE = 3'd4; // Keep for context

    reg [5:0] pending = 6'b0;
    reg [5:0] active = 6'b0;
    reg handling = 1'b0;

    always @(posedge core_clk) begin
        // Default assignments to ensure combinational outputs are well-defined
        // In a synchronous block, these act as next-state defaults
        int_valid <= 1'b0;
        remote_ack <= 2'b00;
        local_ack <= 4'b0000;
        // saved_ctx, int_src, active, handling retain values by default

        // Update pending requests asynchronously to handling logic
        pending[3:0] <= pending[3:0] | local_int_req;
        pending[5:4] <= pending[5:4] | remote_int_req;

        // State machine logic
        if (!handling && (|pending)) begin
            // An interrupt is pending and we are not currently handling one
            int_valid <= 1'b1;
            saved_ctx <= cpu_ctx;
            handling <= 1'b1;

            if (|pending[5:4]) begin
                // Handle remote interrupts (higher priority group)
                // Determine source within remote group based on priority (4 > 5 based on original function)
                // int_src = 4 if pending[4] is set (highest prio within remote), else 5 if pending[5] is set
                // This replaces the get_src function call for remote
                int_src <= pending[4] ? 3'd4 : 3'd5;

                // Acknowledge/Activate all pending remote requests in the group
                remote_ack <= pending[5:4];
                active[5:4] <= pending[5:4];
                pending[5:4] <= 2'b00; // Clear all pending remote requests

            end else begin // |pending[3:0] must be true
                // Handle local interrupts
                // Determine source within local group based on priority (0 > 1 > 2 > 3)
                // This replaces the priority encoding and addition in get_src for local
                reg [1:0] local_prio_idx;
                if (pending[0]) local_prio_idx = 2'b00;
                else if (pending[1]) local_prio_idx = 2'b01;
                else if (pending[2]) local_prio_idx = 2'b10;
                else if (pending[3]) local_prio_idx = 2'b11;
                else local_prio_idx = 2'b00; // Should not happen if |pending[3:0] is true

                // int_src for local is the priority index (0-3)
                int_src <= {1'b0, local_prio_idx}; // int_src is 3 bits, LOCAL_BASE is 0

                // Acknowledge/Activate the selected local request (one-hot)
                local_ack <= 4'b1 << local_prio_idx;
                active[3:0] <= 4'b1 << local_prio_idx;

                // Clear the specific pending bit that was selected
                case (local_prio_idx)
                    2'b00: pending[0] <= 1'b0;
                    2'b01: pending[1] <= 1'b0;
                    2'b10: pending[2] <= 1'b0;
                    2'b11: pending[3] <= 1'b0;
                endcase
            end

        end else if (handling) begin
            // Finish handling the current interrupt (pulsing logic)
            // This block executes in the cycle *after* an interrupt was accepted
            remote_ack <= 2'b00; // Clear acks
            local_ack <= 4'b0000; // Clear acks
            active <= 6'b0; // Clear active flags
            int_valid <= 1'b0; // Deassert valid
            handling <= 1'b0; // Allow new interrupts to be accepted
        end
        // If !handling && !|pending, the default assignments apply, and pending
        // continues to accumulate new requests.
    end

endmodule