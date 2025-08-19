//SystemVerilog
module config_poly_lfsr (
    input  wire        clock,
    input  wire        reset,
    input  wire [15:0] polynomial,  // Configurable taps
    output wire [15:0] rand_out
);
    // Stage 1: Latch shift register and polynomial for feedback calculation
    reg  [15:0] shift_reg_stage1;
    reg  [15:0] polynomial_stage1;
    reg         reset_stage1;

    // Stage 2: Compute feedback (split XOR and AND into two stages)
    reg  [15:0] and_result_stage2;
    reg         reset_stage2;
    reg  [15:0] shift_reg_stage2;
    reg  [15:0] polynomial_stage2;

    // Stage 3: XOR reduction
    reg         feedback_stage3;
    reg         reset_stage3;
    reg  [15:0] shift_reg_stage3;

    // Stage 4: Shift and update shift register
    reg  [15:0] shift_reg_stage4;
    reg         reset_stage4;

    // Stage 5: Output pipeline register
    reg  [15:0] rand_out_stage5;

    // Stage 1: Register inputs
    always @(posedge clock) begin
        shift_reg_stage1   <= reset ? 16'h1 : shift_reg_stage4;
        polynomial_stage1  <= polynomial;
        reset_stage1       <= reset;
    end

    // Stage 2: AND with polynomial
    always @(posedge clock) begin
        and_result_stage2  <= shift_reg_stage1 & polynomial_stage1;
        shift_reg_stage2   <= shift_reg_stage1;
        polynomial_stage2  <= polynomial_stage1;
        reset_stage2       <= reset_stage1;
    end

    // Stage 3: XOR reduction
    always @(posedge clock) begin
        feedback_stage3    <= ^and_result_stage2;
        shift_reg_stage3   <= shift_reg_stage2;
        reset_stage3       <= reset_stage2;
    end

    // Stage 4: Shift and update
    always @(posedge clock) begin
        shift_reg_stage4   <= reset_stage3 ? 16'h1 : {shift_reg_stage3[14:0], feedback_stage3};
        reset_stage4       <= reset_stage3;
    end

    // Stage 5: Output pipeline register
    always @(posedge clock) begin
        rand_out_stage5    <= shift_reg_stage4;
    end

    assign rand_out = rand_out_stage5;

endmodule