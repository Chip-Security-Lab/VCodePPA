//SystemVerilog
module metastability_rng (
    input  wire        clk_sys,
    input  wire        rst_n,
    input  wire        meta_clk,
    output reg  [7:0]  random_value
);

    // Stage 1: Metastable input using clock domain crossing (meta_clk domain)
    reg meta_stage1_q_stage1;
    reg meta_stage1_d_stage1;
    always @(posedge meta_clk or negedge rst_n) begin
        if (!rst_n)
            meta_stage1_q_stage1 <= 1'b0;
        else
            meta_stage1_q_stage1 <= meta_stage1_d_stage1;
    end
    assign meta_stage1_d_stage1 = ~meta_stage1_q_stage1;

    // Stage 2: Synchronize to clk_sys domain (CDC FF1)
    reg meta_stage2_q_stage2;
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            meta_stage2_q_stage2 <= 1'b0;
        else
            meta_stage2_q_stage2 <= meta_stage1_q_stage1;
    end

    // Stage 3: CDC FF2 (improve metastability suppression)
    reg meta_stage3_q_stage3;
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            meta_stage3_q_stage3 <= 1'b0;
        else
            meta_stage3_q_stage3 <= meta_stage2_q_stage2;
    end

    // Stage 4: Feedback calculation (split XOR into pipeline)
    reg feedback_bit_stage4;
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            feedback_bit_stage4 <= 1'b0;
        else
            feedback_bit_stage4 <= meta_stage3_q_stage3 ^ random_value[7];
    end

    // Stage 5: Shift random_value (separate pipeline for shift)
    reg [6:0] random_value_low_stage5;
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            random_value_low_stage5 <= 7'b0;
        else
            random_value_low_stage5 <= random_value[6:0];
    end

    // Stage 6: Combine feedback and shifted value
    reg [7:0] random_value_next_stage6;
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            random_value_next_stage6 <= 8'h42;
        else
            random_value_next_stage6 <= {random_value_low_stage5, feedback_bit_stage4};
    end

    // Stage 7: Register final output
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            random_value <= 8'h42;
        else
            random_value <= random_value_next_stage6;
    end

endmodule