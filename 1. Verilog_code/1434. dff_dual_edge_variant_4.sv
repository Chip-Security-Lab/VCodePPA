//SystemVerilog
module dff_dual_edge (
    input wire clk, rstn,
    input wire d,
    output wire q
);

    // Pipeline stage 1 - Capture data on both edges
    reg q_pos_stage1, q_neg_stage1;
    reg valid_pos_stage1, valid_neg_stage1;

    // Positive edge pipeline stage 1 - Data capture
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            q_pos_stage1 <= 1'b0;
        else
            q_pos_stage1 <= d;
    end

    // Positive edge pipeline stage 1 - Valid flag
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            valid_pos_stage1 <= 1'b0;
        else
            valid_pos_stage1 <= 1'b1;
    end

    // Negative edge pipeline stage 1 - Data capture
    always @(negedge clk or negedge rstn) begin
        if (!rstn)
            q_neg_stage1 <= 1'b0;
        else
            q_neg_stage1 <= d;
    end

    // Negative edge pipeline stage 1 - Valid flag
    always @(negedge clk or negedge rstn) begin
        if (!rstn)
            valid_neg_stage1 <= 1'b0;
        else
            valid_neg_stage1 <= 1'b1;
    end

    // Pipeline stage 2 - Process and select output
    reg q_pos_stage2, q_neg_stage2;
    reg valid_pos_stage2, valid_neg_stage2;
    reg clk_state;

    // Store clock state for selection logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            clk_state <= 1'b0;
        else
            clk_state <= 1'b1;
    end

    // Stage 2 registers - Data propagation for positive edge
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            q_pos_stage2 <= 1'b0;
        else
            q_pos_stage2 <= q_pos_stage1;
    end

    // Stage 2 registers - Valid flag propagation for positive edge
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            valid_pos_stage2 <= 1'b0;
        else
            valid_pos_stage2 <= valid_pos_stage1;
    end

    // Stage 2 registers - Data propagation for negative edge
    always @(negedge clk or negedge rstn) begin
        if (!rstn)
            q_neg_stage2 <= 1'b0;
        else
            q_neg_stage2 <= q_neg_stage1;
    end

    // Stage 2 registers - Valid flag propagation for negative edge
    always @(negedge clk or negedge rstn) begin
        if (!rstn)
            valid_neg_stage2 <= 1'b0;
        else
            valid_neg_stage2 <= valid_neg_stage1;
    end

    // Pipeline stage 3 - Output selection
    reg q_output;
    reg valid_output;

    // Output selection - Data
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            q_output <= 1'b0;
        else
            q_output <= clk_state ? q_pos_stage2 : q_neg_stage2;
    end

    // Output selection - Valid flag
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            valid_output <= 1'b0;
        else
            valid_output <= clk_state ? valid_pos_stage2 : valid_neg_stage2;
    end

    // Forward data when valid
    assign q = valid_output ? q_output : (clk ? q_pos_stage1 : q_neg_stage1);

endmodule