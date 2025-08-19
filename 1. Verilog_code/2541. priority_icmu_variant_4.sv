//SystemVerilog
module priority_icmu #(parameter INT_WIDTH = 8, CTX_WIDTH = 32) (
    input wire clk, rst_n,
    input wire [INT_WIDTH-1:0] int_req,
    input wire [CTX_WIDTH-1:0] current_ctx,
    output wire [INT_WIDTH-1:0] int_ack,
    output wire [CTX_WIDTH-1:0] saved_ctx,
    output wire [2:0] int_id,
    output wire active
);

    // --- Inline Function Definition ---
    // This function finds the index of the highest set bit (priority).
    // It returns a 3-bit value, implying max priority index is 7 (INT_WIDTH <= 8).
    function [2:0] get_priority;
        input [INT_WIDTH-1:0] req;
        integer i;
        begin
            get_priority = 0; // Default if no bits are set
            // Loop from LSB to MSB to find the highest index set.
            for (i = 0; i < INT_WIDTH; i = i+1) begin
                if (req[i]) begin
                    get_priority = i;
                end
            end
        end
    endfunction

    // --- Pipeline Registers ---
    // Stage 1: Latch inputs
    reg [INT_WIDTH-1:0] int_req_s1_reg;
    reg [CTX_WIDTH-1:0] current_ctx_s1_reg;
    reg valid_s1_reg; // Valid signal for Stage 1

    // Stage 2: Latch results from Stage 1 (priority ID and context)
    reg [2:0] id_s2_reg;
    reg [CTX_WIDTH-1:0] ctx_s2_reg; // Context is just passed through
    reg valid_s2_reg; // Valid signal for Stage 2

    // Stage 3: Latch results from Stage 2 (final outputs)
    reg [2:0] id_s3_reg;
    reg [CTX_WIDTH-1:0] ctx_s3_reg;
    reg valid_s3_reg; // Valid signal for Stage 3

    // --- Internal Signals ---
    // Combinational priority calculation result from Stage 1 latched data
    wire [2:0] id_s2_comb;

    // Signal indicating if the pipeline is currently processing a request in any stage
    wire pipeline_busy;

    // --- Combinational Logic ---

    // Priority calculation based on the latched request in Stage 1
    // This computation is now effectively part of the transition from Stage 1 to Stage 2
    assign id_s2_comb = get_priority(int_req_s1_reg);

    // Pipeline is busy if any stage holds valid data.
    // This signal is used to gate new inputs, similar to the original 'active' behavior.
    assign pipeline_busy = valid_s1_reg | valid_s2_reg | valid_s3_reg;

    // --- Sequential Logic ---

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers and valid signals
            int_req_s1_reg <= {INT_WIDTH{1'b0}};
            current_ctx_s1_reg <= {CTX_WIDTH{1'b0}};
            valid_s1_reg <= 1'b0;

            id_s2_reg <= 3'b000;
            ctx_s2_reg <= {CTX_WIDTH{1'b0}};
            valid_s2_reg <= 1'b0;

            id_s3_reg <= 3'b000;
            ctx_s3_reg <= {CTX_WIDTH{1'b0}};
            valid_s3_reg <= 1'b0;
        end else begin
            // --- Stage 1 Register Update (Input Latch) ---
            // Latch new request if pipeline is not busy and there is an interrupt request
            if (|int_req & ~pipeline_busy) begin
                int_req_s1_reg <= int_req;
                current_ctx_s1_reg <= current_ctx;
                valid_s1_reg <= 1'b1; // Mark Stage 1 data as valid
            end else begin
                // If no new request or pipeline is busy, insert a bubble
                // If Stage 1 data moves to Stage 2, valid_s1_reg should go low unless a new input replaces it.
                // The original logic only sets valid_s1_reg to 1 if a new input is accepted.
                // Let's keep that behavior: valid_s1_reg goes low if no new input is accepted.
                 valid_s1_reg <= (|int_req & ~pipeline_busy); // Valid only if new data is latched
                 // Data registers retain old value or become don't care when valid is 0
            end

            // --- Stage 2 Register Update (Priority Calc Latch) ---
            // Move data from Stage 1 to Stage 2 if Stage 1 has valid data
            if (valid_s1_reg) begin
                id_s2_reg <= id_s2_comb; // Latch the calculated ID from Stage 1 latched data
                ctx_s2_reg <= current_ctx_s1_reg; // Latch the context from Stage 1
                valid_s2_reg <= 1'b1; // Mark Stage 2 data as valid
            end else begin
                // If Stage 1 had no valid data, propagate the bubble
                valid_s2_reg <= 1'b0;
                // Data registers retain old value or become don't care when valid is 0
            end

            // --- Stage 3 Register Update (Output Latch) ---
            // Move data from Stage 2 to Stage 3 if Stage 2 has valid data
            if (valid_s2_reg) begin
                id_s3_reg <= id_s2_reg; // Latch the ID from Stage 2
                ctx_s3_reg <= ctx_s2_reg; // Latch the context from Stage 2
                valid_s3_reg <= 1'b1; // Mark Stage 3 data as valid
            end else begin
                // If Stage 2 had no valid data, propagate the bubble
                valid_s3_reg <= 1'b0;
                // Data registers retain old value or become don't care when valid is 0
            end
        end
    end

    // --- Output Assignments ---
    // Outputs are driven by the last stage (Stage 3) only when its data is valid.
    // When valid_s3_reg is low, outputs are set to default/inactive values.
    assign int_ack = (valid_s3_reg) ? (1 << id_s3_reg) : {INT_WIDTH{1'b0}};
    assign saved_ctx = (valid_s3_reg) ? ctx_s3_reg : {CTX_WIDTH{1'b0}};
    assign int_id = (valid_s3_reg) ? id_s3_reg : 3'b000;
    // The 'active' output signal indicates that the output stage (Stage 3) has a valid result.
    assign active = valid_s3_reg;

endmodule