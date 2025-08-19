//SystemVerilog
module priority_icmu #(parameter INT_WIDTH = 8, CTX_WIDTH = 32) (
    input wire clk, rst_n,
    input wire [INT_WIDTH-1:0] int_req,
    input wire [CTX_WIDTH-1:0] current_ctx,
    output reg [INT_WIDTH-1:0] int_ack,
    output reg [CTX_WIDTH-1:0] saved_ctx,
    output reg [2:0] int_id,
    output reg active
);

    // Internal mask register - retains value unless reset
    // Used in Stage 0 combinatorial logic
    reg [INT_WIDTH-1:0] int_mask;

    // Optimized get_priority function implementing MSB priority with 3-bit output truncation.
    // This structure is typically synthesized into an efficient priority encoder.
    // This function is purely combinatorial.
    function automatic [2:0] get_priority;
        input [INT_WIDTH-1:0] req;
        integer msb_idx;
        reg found;
        integer i;
    begin
        msb_idx = 0; // Default value if no bit is set
        found = 0;

        // Iterate from MSB down to LSB to find the highest set bit
        for (i = INT_WIDTH - 1; i >= 0; i = i - 1) begin
            // If the current bit is high and we haven't found the MSB set bit yet
            if (req[i] && !found) begin
                msb_idx = i;   // Record the index
                found = 1;     // Set the found flag to prevent further updates
            end
        end

        // Assign the lower 3 bits of the found index to the function's output (truncation)
        get_priority = msb_idx[2:0];
    end
    endfunction

    // Stage 0: Combinatorial Logic - Calculates trigger condition, priority ID, and ACK based on current inputs and previous state
    // Inputs: int_req, current_ctx (used in Stage 1/2), int_mask (prev cycle), active (prev cycle)
    // Outputs: s0_masked_req, s0_trigger, s0_int_id, s0_int_ack
    wire [INT_WIDTH-1:0] s0_masked_req;
    wire s0_trigger;
    wire [2:0] s0_int_id;
    wire [INT_WIDTH-1:0] s0_int_ack; // Calculate potential ACK value

    assign s0_masked_req = int_req & ~int_mask; // int_mask is a register value from previous cycle
    assign s0_trigger = (|s0_masked_req) & ~active; // active is a register value from previous cycle
    assign s0_int_id = get_priority(s0_masked_req);
    assign s0_int_ack = (s0_trigger) ? (1 << s0_int_id) : {INT_WIDTH{1'b0}}; // Calculate potential ACK

    // Stage 1: Registering combinatorial results and inputs for Stage 2
    // Inputs: s0_trigger, s0_int_id, s0_int_ack, current_ctx
    // Outputs (Registered): s1_trigger_r, s1_int_id_r, s1_int_ack_r, s1_current_ctx_r
    reg s1_trigger_r;
    reg [2:0] s1_int_id_r;
    reg [INT_WIDTH-1:0] s1_int_ack_r;
    reg [CTX_WIDTH-1:0] s1_current_ctx_r; // Pass current_ctx through

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_trigger_r <= 1'b0;
            s1_int_id_r <= {3{1'b0}};
            s1_int_ack_r <= {INT_WIDTH{1'b0}};
            s1_current_ctx_r <= {CTX_WIDTH{1'b0}};
        end else begin
            s1_trigger_r <= s0_trigger;
            s1_int_id_r <= s0_int_id;
            s1_int_ack_r <= s0_int_ack;
            s1_current_ctx_r <= current_ctx; // current_ctx is an input, register it directly
        end
    end

    // Stage 2: Registered Outputs with Latching Logic and int_mask reset
    // Inputs: s1_trigger_r, s1_int_id_r, s1_int_ack_r, s1_current_ctx_r
    // Outputs (Registered): int_ack, saved_ctx, int_id, active, int_mask (internal register)
    // int_ack, saved_ctx, int_id, active, int_mask are all reset together in the original code.
    // They are all 'reg' types that hold their value if not assigned.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_ack <= {INT_WIDTH{1'b0}};
            saved_ctx <= {CTX_WIDTH{1'b0}};
            int_id <= {3{1'b0}};
            active <= 1'b0;
            int_mask <= {INT_WIDTH{1'b0}}; // int_mask reset here to match original grouping
        end else begin
            // Latch new values into outputs only if the trigger condition from Stage 1 was met
            if (s1_trigger_r) begin
                int_id <= s1_int_id_r;
                saved_ctx <= s1_current_ctx_r;
                int_ack <= s1_int_ack_r;
                active <= 1'b1; // Set active flag
            end
            // Else, outputs int_id, saved_ctx, int_ack, active hold their value.
            // int_mask is only ever assigned during reset, so it also holds its value.
        end
    end

endmodule