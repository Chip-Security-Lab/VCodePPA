//SystemVerilog
module dist_icmu (
    input wire core_clk,
    input wire [3:0] local_int_req,
    input wire [1:0] remote_int_req,
    input wire [31:0] cpu_ctx,
    output reg [31:0] saved_ctx,
    output reg [2:0] int_src,
    output reg int_valid,
    output reg local_ack,
    output reg [1:0] remote_ack
);

    localparam LOCAL_BASE = 0;
    localparam REMOTE_BASE = 4;

    // State machine for 3-stage pipeline control
    localparam [1:0] STATE_IDLE       = 2'b00;
    localparam [1:0] STATE_STAGE1_CALC = 2'b01; // Calculate source/type
    localparam [1:0] STATE_STAGE2_BUF  = 2'b10; // Buffer results
    localparam [1:0] STATE_STAGE3_GEN  = 2'b11; // Generate outputs

    reg [1:0] state = STATE_IDLE;

    // Main pending interrupt register
    reg [5:0] pending = 6'b0;

    // Internal registers for active and handling status (mirroring original behavior)
    reg [5:0] active = 6'b0;
    reg handling = 1'b0;

    // Pipeline registers for Stage 1 (captured in IDLE)
    reg [5:0] pending_s1; // Captured pending state at detection
    reg [31:0] cpu_ctx_s1; // Captured CPU context

    // Pipeline registers for Stage 2 (calculated in STAGE1_CALC)
    reg is_remote_s2;
    reg [2:0] int_src_s2;

    // Pipeline registers for Stage 3 (buffered from S1/S2 in STAGE2_BUF)
    reg [5:0] pending_s3;
    reg [31:0] cpu_ctx_s3;
    reg is_remote_s3;
    reg [2:0] int_src_s3;


    // Function to get interrupt source ID
    function [2:0] get_src;
        input [3:0] src_bits;
        input [2:0] base;
        begin
            casez(src_bits)
                4'b???1: get_src = base;
                4'b??10: get_src = base + 1;
                4'b?100: get_src = base + 2;
                4'b1000: get_src = base + 3;
                default: get_src = base; // Should not happen if |src_bits is true
            endcase
        end
    endfunction

    always @(posedge core_clk) begin
        // Update pending register with new requests (combinatorial update)
        pending[3:0] <= pending[3:0] | local_int_req;
        pending[5:4] <= pending[5:4] | remote_int_req;

        // Default assignments for outputs and internal state (applied every cycle)
        // These are overwritten in STATE_STAGE3_GEN
        int_valid <= 1'b0;
        local_ack <= 1'b0;
        remote_ack <= 2'b00;
        active <= 6'b0;
        handling <= 1'b0;
        // saved_ctx and int_src hold their values by default

        // State machine
        case (state)
            STATE_IDLE: begin
                // Check for pending interrupts
                if (|pending) begin
                    // Transition to STAGE1_CALC state
                    state <= STATE_STAGE1_CALC;
                    // Capture state for pipeline stage 1
                    pending_s1 <= pending; // Capture current pending state
                    cpu_ctx_s1 <= cpu_ctx;         // Capture current CPU context
                end else begin
                    // Stay in IDLE state
                    state <= STATE_IDLE;
                end
            end

            STATE_STAGE1_CALC: begin
                // Calculate interrupt source and priority based on captured state (pending_s1)
                is_remote_s2 <= |pending_s1[5:4];
                if (|pending_s1[5:4]) begin // Use pending_s1 for calculation
                    int_src_s2 <= get_src(pending_s1[5:4], REMOTE_BASE);
                end else begin
                    int_src_s2 <= get_src(pending_s1[3:0], LOCAL_BASE);
                end
                // cpu_ctx_s1 is passed through

                // Transition to STAGE2_BUF state
                state <= STATE_STAGE2_BUF;
            end

            STATE_STAGE2_BUF: begin
                // Buffer results from STAGE1_CALC and pass S1 captures
                is_remote_s3 <= is_remote_s2;
                int_src_s3 <= int_src_s2;

                pending_s3 <= pending_s1; // Pass captured pending
                cpu_ctx_s3 <= cpu_ctx_s1; // Pass captured context

                // Transition to STAGE3_GEN state
                state <= STATE_STAGE3_GEN;
            end

            STATE_STAGE3_GEN: begin
                // Generate outputs and update state based on pipelined values (s3 signals)
                saved_ctx <= cpu_ctx_s3;
                int_src <= int_src_s3;
                int_valid <= 1'b1; // Valid output in this state
                handling <= 1'b1; // Handling is active

                if (is_remote_s3) begin
                    // Handle remote interrupt using s3 values
                    remote_ack <= pending_s3[5:4]; // Ack based on captured pending_s3
                    active[5:4] <= pending_s3[5:4]; // Set active for remote based on pending_s3
                    active[3:0] <= 4'b0;                      // Clear local active bits
                    // Clear the handled remote pending bits in the main pending register
                    pending[5:4] <= 2'b00; // Clear all remote pending when handled
                end else begin
                    // Handle local interrupt using s3 values
                    local_ack <= 1'b1 << int_src_s3[1:0]; // Ack based on pipelined source_s3
                    active[3:0] <= 1'b1 << int_src_s3[1:0]; // Set active for local based on source_s3
                    active[5:4] <= 2'b0;                      // Clear remote active bits
                    // Clear the specific handled local pending bit in the main pending register
                    pending[int_src_s3[1:0]] <= 1'b0; // Clear the specific bit using source_s3 index
                end

                // Transition back to IDLE state
                state <= STATE_IDLE;
            end

            default: begin
                // Should not reach here, reset to IDLE
                state <= STATE_IDLE;
            end
        endcase
    end

endmodule