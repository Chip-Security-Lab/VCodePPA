//SystemVerilog
module adaptive_clock_gate (
    input  wire clk_in,
    input  wire [7:0] activity_level,
    input  wire rst_n,
    output wire clk_out
);
    // Stage 1: 活动水平评估阶段
    reg [7:0] activity_level_stage1;
    reg valid_stage1;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            activity_level_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            activity_level_stage1 <= activity_level;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: 比较处理阶段
    reg comparison_result_stage2;
    reg valid_stage2;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            comparison_result_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            comparison_result_stage2 <= (activity_level_stage1 > 8'd10);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: 输出决策阶段
    reg gate_enable_stage3;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            gate_enable_stage3 <= 1'b0;
        end else begin
            gate_enable_stage3 <= comparison_result_stage2 & valid_stage2;
        end
    end
    
    // 最终时钟门控
    assign clk_out = clk_in & gate_enable_stage3;
endmodule