//SystemVerilog
module dram_burst_length #(
    parameter MAX_BURST = 8
)(
    input clk,
    input rst_n,
    input [2:0] burst_cfg,
    output reg burst_end,
    output reg [3:0] burst_counter
);

    // Pipeline stage 1: Configuration decode
    reg [3:0] burst_max_stage1;
    reg [2:0] burst_cfg_stage1;
    
    // Pipeline stage 2: Counter logic
    reg [3:0] burst_max_stage2;
    reg [3:0] next_counter_stage2;
    reg counter_eq_max_stage2;
    
    // Pipeline stage 3: Output generation
    reg [3:0] next_counter_stage3;
    reg counter_eq_max_stage3;

    // Stage 1: Configuration decode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_max_stage1 <= 4'd0;
            burst_cfg_stage1 <= 3'd0;
        end else begin
            burst_max_stage1 <= {1'b0, burst_cfg} << 1;
            burst_cfg_stage1 <= burst_cfg;
        end
    end

    // Stage 2: Counter comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_max_stage2 <= 4'd0;
            next_counter_stage2 <= 4'd0;
            counter_eq_max_stage2 <= 1'b0;
        end else begin
            burst_max_stage2 <= burst_max_stage1;
            next_counter_stage2 <= (burst_counter == burst_max_stage1) ? 4'd0 : burst_counter + 1;
            counter_eq_max_stage2 <= (burst_counter == burst_max_stage1);
        end
    end

    // Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_counter <= 4'd0;
            burst_end <= 1'b0;
            next_counter_stage3 <= 4'd0;
            counter_eq_max_stage3 <= 1'b0;
        end else begin
            burst_counter <= next_counter_stage2;
            burst_end <= counter_eq_max_stage2;
            next_counter_stage3 <= next_counter_stage2;
            counter_eq_max_stage3 <= counter_eq_max_stage2;
        end
    end

endmodule