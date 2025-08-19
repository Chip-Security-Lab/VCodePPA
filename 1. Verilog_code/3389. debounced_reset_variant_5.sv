//SystemVerilog
module debounced_reset #(
    parameter DEBOUNCE_COUNT = 3
)(
    input wire clk,
    input wire noisy_reset,
    output reg clean_reset
);
    // 流水线阶段1: 捕获输入并检测变化
    reg noisy_reset_stage1;
    reg reset_ff_stage1;
    reg edge_detected_stage1;
    
    // 流水线阶段2: 计数器控制
    reg [1:0] count_stage2;
    reg reset_ff_stage2;
    reg edge_detected_stage2;
    
    // 流水线阶段3: 输出生成
    reg reset_ff_stage3;
    reg count_done_stage3;
    
    // 流水线第一阶段：检测边缘
    always @(posedge clk) begin
        noisy_reset_stage1 <= noisy_reset;
        reset_ff_stage1 <= noisy_reset_stage1;
        edge_detected_stage1 <= (reset_ff_stage1 != noisy_reset_stage1);
    end
    
    // 流水线第二阶段：计数器逻辑
    always @(posedge clk) begin
        reset_ff_stage2 <= reset_ff_stage1;
        edge_detected_stage2 <= edge_detected_stage1;
        
        if (edge_detected_stage2) begin
            count_stage2 <= 0;
        end else if (count_stage2 < DEBOUNCE_COUNT) begin
            count_stage2 <= count_stage2 + 1'b1;
        end
    end
    
    // 流水线第三阶段：输出生成
    always @(posedge clk) begin
        reset_ff_stage3 <= reset_ff_stage2;
        count_done_stage3 <= (count_stage2 == DEBOUNCE_COUNT);
        
        if (count_done_stage3) begin
            clean_reset <= reset_ff_stage3;
        end
    end
endmodule