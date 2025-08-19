//SystemVerilog
module dram_burst_length #(
    parameter MAX_BURST = 8
)(
    input clk,
    input rst_n,
    input [2:0] burst_cfg,
    output reg burst_end
);

    // Pipeline stage 1 registers
    reg [3:0] burst_max_stage1;
    reg [3:0] burst_counter_stage1;
    reg valid_stage1;
    reg [3:0] next_burst_counter_stage1;

    // Pipeline stage 2 registers
    reg [3:0] burst_counter_stage2;
    reg valid_stage2;
    reg burst_end_stage2;
    reg [3:0] next_burst_counter_stage2;

    // Stage 1: Calculate burst_max and prepare next counter value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_max_stage1 <= 4'd0;
            burst_counter_stage1 <= 4'd0;
            valid_stage1 <= 1'b0;
            next_burst_counter_stage1 <= 4'd0;
        end else begin
            burst_max_stage1 <= {1'b0, burst_cfg} << 1;
            next_burst_counter_stage1 <= (burst_counter_stage2 == burst_max_stage1) ? 4'd0 : burst_counter_stage2 + 1;
            burst_counter_stage1 <= next_burst_counter_stage1;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Compare and generate burst_end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_counter_stage2 <= 4'd0;
            valid_stage2 <= 1'b0;
            burst_end_stage2 <= 1'b0;
            next_burst_counter_stage2 <= 4'd0;
        end else begin
            next_burst_counter_stage2 <= burst_counter_stage1;
            burst_counter_stage2 <= next_burst_counter_stage2;
            valid_stage2 <= valid_stage1;
            burst_end_stage2 <= (burst_counter_stage1 == burst_max_stage1) ? 1'b1 : 1'b0;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_end <= 1'b0;
        end else begin
            burst_end <= burst_end_stage2;
        end
    end

endmodule