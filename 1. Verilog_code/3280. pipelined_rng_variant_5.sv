//SystemVerilog
module pipelined_rng (
    input wire clk,
    input wire rst_n,
    output wire [31:0] random_data
);
    // Stage 1: LFSR
    reg  [31:0] lfsr_state;
    wire [31:0] lfsr_next_state;
    wire lfsr_feedback_bit;
    wire lfsr_xor_31_28;
    wire lfsr_xor_15_0;

    // Stage 2: Bit Shuffle
    reg  [31:0] shuffle_reg_stage1, shuffle_reg_stage2;
    wire [31:0] shuffle_concat_bits;
    wire [31:0] shuffle_rotated;
    wire [31:0] shuffle_xor_result;

    // Stage 3: Nonlinear Transformation (2 pipeline stages)
    reg  [31:0] nonlinear_reg_a, nonlinear_reg_b, nonlinear_reg_out;
    wire [31:0] nonlinear_shifted, nonlinear_xor_result, nonlinear_sum_result;

    // LFSR feedback calculation: split complex XOR into steps
    assign lfsr_xor_31_28 = lfsr_state[31] ^ lfsr_state[28];
    assign lfsr_xor_15_0  = lfsr_state[15] ^ lfsr_state[0];
    assign lfsr_feedback_bit = lfsr_xor_31_28 ^ lfsr_xor_15_0;

    assign lfsr_next_state = {lfsr_state[30:0], lfsr_feedback_bit};

    // LFSR pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state <= 32'h12345678;
        end else begin
            lfsr_state <= lfsr_next_state;
        end
    end

    // Stage 2: Bit shuffle - split into steps
    // 1. Swap upper/lower 16 bits
    assign shuffle_concat_bits = {lfsr_state[15:0], lfsr_state[31:16]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shuffle_reg_stage1 <= 32'h87654321;
        end else begin
            shuffle_reg_stage1 <= shuffle_concat_bits;
        end
    end

    // 2. Rotate right by 8
    assign shuffle_rotated = {shuffle_reg_stage1[7:0], shuffle_reg_stage1[31:8]};
    // 3. XOR with original
    assign shuffle_xor_result = shuffle_reg_stage1 ^ shuffle_rotated;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shuffle_reg_stage2 <= 32'h0;
        end else begin
            shuffle_reg_stage2 <= shuffle_xor_result;
        end
    end

    // Stage 3: Nonlinear transformation - pipelined and split into steps
    // Register pipeline stages
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nonlinear_reg_a <= 32'hABCDEF01;
        end else begin
            nonlinear_reg_a <= nonlinear_reg_b;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nonlinear_reg_b <= 32'h0;
        end else begin
            nonlinear_reg_b <= shuffle_reg_stage2;
        end
    end

    // Nonlinear transformation: split into steps
    assign nonlinear_shifted    = nonlinear_reg_a << 5;
    assign nonlinear_xor_result = nonlinear_reg_a ^ nonlinear_shifted;
    assign nonlinear_sum_result = nonlinear_reg_b + nonlinear_xor_result;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nonlinear_reg_out <= 32'h0;
        end else begin
            nonlinear_reg_out <= nonlinear_sum_result;
        end
    end

    assign random_data = nonlinear_reg_out;

endmodule