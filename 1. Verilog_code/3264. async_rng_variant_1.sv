//SystemVerilog
module async_rng (
    input wire clk_fast,
    input wire clk_slow,
    input wire rst_n,
    output wire [15:0] random_val
);
    // Fast Counter Pipeline: Stage 1 and Stage 2
    reg [15:0] fast_counter_stage1;
    reg [15:0] fast_counter_stage2;

    // Pipeline for capturing value from fast domain to slow domain
    reg [15:0] fast_counter_sync_stage1;
    reg [15:0] fast_counter_sync_stage2;

    // XOR Pipeline: Stage 1 and Stage 2
    reg [15:0] xor_input_stage1;
    reg [15:0] xor_result_stage1;
    reg [15:0] xor_result_stage2;

    // Output register
    reg [15:0] random_val_stage1;
    reg [15:0] random_val_stage2;

    // Fast-running counter pipeline (clk_fast domain)
    always @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n) begin
            fast_counter_stage1 <= 16'h0;
            fast_counter_stage2 <= 16'h0;
        end else if (rst_n && clk_fast) begin
            fast_counter_stage1 <= fast_counter_stage1 + 1'b1;
            fast_counter_stage2 <= fast_counter_stage1;
        end
    end

    // CDC pipeline: synchronize fast_counter to clk_slow domain (2-stage)
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            fast_counter_sync_stage1 <= 16'h0;
            fast_counter_sync_stage2 <= 16'h0;
        end else if (rst_n && clk_slow) begin
            fast_counter_sync_stage1 <= fast_counter_stage2;
            fast_counter_sync_stage2 <= fast_counter_sync_stage1;
        end
    end

    // XOR pipeline (split into two stages for higher frequency)
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            xor_input_stage1 <= 16'h1;
            xor_result_stage1 <= 16'h0;
            xor_result_stage2 <= 16'h0;
        end else if (rst_n && clk_slow) begin
            xor_input_stage1 <= random_val_stage2 << 1;
            xor_result_stage1 <= fast_counter_sync_stage2 ^ (random_val_stage2 << 1);
            xor_result_stage2 <= xor_result_stage1;
        end
    end

    // Output pipeline stages
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            random_val_stage1 <= 16'h1;
            random_val_stage2 <= 16'h1;
        end else if (rst_n && clk_slow) begin
            random_val_stage1 <= xor_result_stage2;
            random_val_stage2 <= random_val_stage1;
        end
    end

    assign random_val = random_val_stage2;
endmodule