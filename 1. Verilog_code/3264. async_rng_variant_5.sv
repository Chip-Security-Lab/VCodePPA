//SystemVerilog
module async_rng (
    input wire clk_fast,
    input wire clk_slow,
    input wire rst_n,
    output wire [15:0] random_val
);
    // Stage 1: Fast counter
    reg [15:0] fast_counter_stage1;
    always @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n)
            fast_counter_stage1 <= 16'h0;
        else
            fast_counter_stage1 <= fast_counter_stage1 + 1'b1;
    end

    // Stage 2: Synchronize fast_counter to clk_slow domain
    reg [15:0] fast_counter_stage2;
    reg [15:0] fast_counter_stage3;
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            fast_counter_stage2 <= 16'h0;
            fast_counter_stage3 <= 16'h0;
        end else begin
            fast_counter_stage2 <= fast_counter_stage1;
            fast_counter_stage3 <= fast_counter_stage2;
        end
    end

    // Stage 3: Pipeline captured_value
    reg [15:0] captured_value_stage1;
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n)
            captured_value_stage1 <= 16'h1;
        else
            captured_value_stage1 <= fast_counter_stage3 ^ (captured_value_stage1 << 1);
    end

    // Stage 4: Pipeline output for timing closure
    reg [15:0] random_val_stage1;
    reg [15:0] random_val_stage2;
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            random_val_stage1 <= 16'h1;
            random_val_stage2 <= 16'h1;
        end else begin
            random_val_stage1 <= captured_value_stage1;
            random_val_stage2 <= random_val_stage1;
        end
    end

    assign random_val = random_val_stage2;
endmodule