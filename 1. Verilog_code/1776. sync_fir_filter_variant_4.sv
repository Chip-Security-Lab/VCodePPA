//SystemVerilog
module sync_fir_filter #(
    parameter DATA_W = 12,
    parameter TAP_W = 8,
    parameter TAPS = 4
)(
    input clk, rst,
    input [DATA_W-1:0] sample_in,
    input sample_valid,
    input [TAP_W-1:0] coeffs [TAPS-1:0],
    output reg [DATA_W+TAP_W-1:0] filtered_out,
    output reg filtered_valid
);
    // 延迟线寄存器
    reg [DATA_W-1:0] delay_line [TAPS-1:0];
    
    // 流水线阶段寄存器
    reg [DATA_W-1:0] sample_stage1;
    reg [DATA_W-1:0] delay_stage1 [TAPS-1:0];
    reg [TAP_W-1:0] coeffs_stage1 [TAPS-1:0];
    reg valid_stage1;
    
    // 乘法结果寄存器
    reg [DATA_W+TAP_W-1:0] mult_stage2 [TAPS-1:0];
    reg valid_stage2;
    
    // 第一级加法结果寄存器
    reg [DATA_W+TAP_W-1:0] add_stage3 [TAPS/2-1:0];
    reg valid_stage3;
    
    // 最终加法结果寄存器
    reg [DATA_W+TAP_W-1:0] final_sum_stage4;
    reg valid_stage4;
    
    integer i;
    
    // 流水线阶段1: 输入采样和移位寄存器
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                delay_line[i] <= 0;
                delay_stage1[i] <= 0;
                coeffs_stage1[i] <= 0;
            end
            sample_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            // 保存输入信号到第一级
            sample_stage1 <= sample_in;
            valid_stage1 <= sample_valid;
            
            // 将系数传递到第一级
            for (i = 0; i < TAPS; i = i + 1) begin
                coeffs_stage1[i] <= coeffs[i];
            end
            
            // 移位延迟线
            if (sample_valid) begin
                for (i = TAPS-1; i > 0; i = i - 1)
                    delay_line[i] <= delay_line[i-1];
                delay_line[0] <= sample_in;
            end
            
            // 将延迟线内容传递到下一级
            for (i = 0; i < TAPS; i = i + 1) begin
                delay_stage1[i] <= delay_line[i];
            end
        end
    end
    
    // 流水线阶段2: 执行乘法操作
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                mult_stage2[i] <= 0;
            end
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            for (i = 0; i < TAPS; i = i + 1) begin
                mult_stage2[i] <= delay_stage1[i] * coeffs_stage1[i];
            end
        end
    end
    
    // 流水线阶段3: 第一级加法
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAPS/2; i = i + 1) begin
                add_stage3[i] <= 0;
            end
            valid_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            for (i = 0; i < TAPS/2; i = i + 1) begin
                add_stage3[i] <= mult_stage2[i*2] + mult_stage2[i*2+1];
            end
        end
    end
    
    // 流水线阶段4: 最终加法
    always @(posedge clk) begin
        if (rst) begin
            final_sum_stage4 <= 0;
            valid_stage4 <= 0;
        end else begin
            valid_stage4 <= valid_stage3;
            final_sum_stage4 <= add_stage3[0] + add_stage3[1];
        end
    end
    
    // 输出阶段
    always @(posedge clk) begin
        if (rst) begin
            filtered_out <= 0;
            filtered_valid <= 0;
        end else begin
            filtered_out <= final_sum_stage4;
            filtered_valid <= valid_stage4;
        end
    end
endmodule