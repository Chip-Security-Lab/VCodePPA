//SystemVerilog
module param_lfsr_rng #(
    parameter WIDTH = 16,
    parameter [WIDTH-1:0] SEED = {WIDTH{1'b1}},
    parameter [WIDTH-1:0] TAPS = 16'h8016
)(
    input  wire                 clock,
    input  wire                 reset_n,
    input  wire                 enable,
    output wire [WIDTH-1:0]     random_value
);

    // Stage 1: AND result of lfsr_state and TAPS
    reg [WIDTH-1:0] lfsr_state_stage1;
    reg [WIDTH-1:0] and_result_stage1;

    // Stage 2: Feedback (XOR reduction), pipeline lfsr_state
    reg             feedback_stage2;
    reg [WIDTH-1:0] lfsr_state_stage2;

    // Stage 3: Next LFSR state, pipeline lfsr_state
    reg [WIDTH-1:0] next_lfsr_state_stage3;
    reg [WIDTH-1:0] lfsr_state_stage3;

    // Stage 4: Registered LFSR state
    reg [WIDTH-1:0] lfsr_state_stage4;

    // Stage 1: Compute and_result
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            lfsr_state_stage1    <= SEED;
            and_result_stage1    <= (SEED & TAPS);
        end else if (enable) begin
            lfsr_state_stage1    <= lfsr_state_stage4;
            and_result_stage1    <= (lfsr_state_stage4 & TAPS);
        end
    end

    // Stage 2: Compute feedback (XOR reduction), pipeline lfsr_state
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            feedback_stage2      <= ^(SEED & TAPS);
            lfsr_state_stage2    <= SEED;
        end else if (enable) begin
            feedback_stage2      <= ^and_result_stage1;
            lfsr_state_stage2    <= lfsr_state_stage1;
        end
    end

    // Stage 3: Optimized next LFSR state generation
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            next_lfsr_state_stage3   <= SEED;
            lfsr_state_stage3        <= SEED;
        end else if (enable) begin
            next_lfsr_state_stage3   <= {lfsr_state_stage2[WIDTH-2:0], feedback_stage2};
            lfsr_state_stage3        <= lfsr_state_stage2;
        end
    end

    // Stage 4: Register new LFSR state
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            lfsr_state_stage4 <= SEED;
        else if (enable)
            lfsr_state_stage4 <= next_lfsr_state_stage3;
    end

    assign random_value = lfsr_state_stage4;

endmodule