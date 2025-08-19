//SystemVerilog
module hysteresis_recovery (
    input wire sample_clk,
    input wire rst_n,
    input wire [9:0] adc_value,
    input wire [9:0] high_threshold,
    input wire [9:0] low_threshold,
    output reg [9:0] clean_signal,
    output reg signal_present
);
    // 增加流水线级数，将状态判断和数据处理分离
    
    // 流水线寄存器 - 第一级
    reg [9:0] adc_value_stage1;
    reg [9:0] high_threshold_stage1;
    reg [9:0] low_threshold_stage1;
    reg state_stage1;
    
    // 流水线寄存器 - 第二级
    reg [9:0] adc_value_stage2;
    reg state_stage2;
    reg compare_high_result;
    reg compare_low_result;
    
    // 流水线寄存器 - 第三级
    reg [9:0] adc_value_stage3;
    reg state_stage3;
    reg compare_high_result_stage3;
    reg compare_low_result_stage3;
    
    // Stage 1: 数据采集和锁存
    always @(posedge sample_clk) begin
        if (!rst_n) begin
            adc_value_stage1 <= 10'd0;
            high_threshold_stage1 <= 10'd0;
            low_threshold_stage1 <= 10'd0;
            state_stage1 <= 1'b0;
        end else begin
            adc_value_stage1 <= adc_value;
            high_threshold_stage1 <= high_threshold;
            low_threshold_stage1 <= low_threshold;
            state_stage1 <= state_stage3;
        end
    end
    
    // Stage 2: 比较器逻辑计算
    always @(posedge sample_clk) begin
        if (!rst_n) begin
            adc_value_stage2 <= 10'd0;
            state_stage2 <= 1'b0;
            compare_high_result <= 1'b0;
            compare_low_result <= 1'b0;
        end else begin
            adc_value_stage2 <= adc_value_stage1;
            state_stage2 <= state_stage1;
            compare_high_result <= (adc_value_stage1 > high_threshold_stage1);
            compare_low_result <= (adc_value_stage1 < low_threshold_stage1);
        end
    end
    
    // Stage 3: 状态更新逻辑
    always @(posedge sample_clk) begin
        if (!rst_n) begin
            adc_value_stage3 <= 10'd0;
            state_stage3 <= 1'b0;
            compare_high_result_stage3 <= 1'b0;
            compare_low_result_stage3 <= 1'b0;
        end else begin
            adc_value_stage3 <= adc_value_stage2;
            compare_high_result_stage3 <= compare_high_result;
            compare_low_result_stage3 <= compare_low_result;
            
            // 状态转换逻辑
            if (state_stage2 == 1'b0 && compare_high_result) begin
                state_stage3 <= 1'b1;
            end else if (state_stage2 == 1'b1 && compare_low_result) begin
                state_stage3 <= 1'b0;
            end else begin
                state_stage3 <= state_stage2;
            end
        end
    end
    
    // Stage 4: 输出生成
    always @(posedge sample_clk) begin
        if (!rst_n) begin
            clean_signal <= 10'd0;
            signal_present <= 1'b0;
        end else begin
            // 输出逻辑
            if (state_stage3 == 1'b0) begin
                // 低状态
                if (compare_high_result_stage3) begin
                    clean_signal <= adc_value_stage3;
                    signal_present <= 1'b1;
                end else begin
                    clean_signal <= 10'd0;
                    signal_present <= 1'b0;
                end
            end else begin
                // 高状态
                if (compare_low_result_stage3) begin
                    clean_signal <= 10'd0;
                    signal_present <= 1'b0;
                end else begin
                    clean_signal <= adc_value_stage3;
                    signal_present <= 1'b1;
                end
            end
        end
    end
endmodule