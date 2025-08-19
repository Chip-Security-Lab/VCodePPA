//SystemVerilog
module quadrature_sine(
    input clk,
    input reset,
    input [7:0] freq_ctrl,
    output reg [7:0] sine,
    output reg [7:0] cosine
);
    // 相位累加和索引计算的多级流水线
    reg [7:0] phase_stage1, phase_stage2, phase_stage3, phase_stage4;
    reg [7:0] sin_lut [0:7];
    
    // 各阶段索引寄存器
    reg [2:0] phase_index_stage1, phase_index_stage2, phase_index_stage3, phase_index_stage4;
    reg [2:0] cos_index_stage1, cos_index_stage2, cos_index_stage3, cos_index_stage4;
    
    // 增加预计算和查表的中间结果寄存器
    reg [7:0] sin_value_stage4;
    reg [7:0] cos_value_stage4;
    
    initial begin
        sin_lut[0] = 8'd128; sin_lut[1] = 8'd218;
        sin_lut[2] = 8'd255; sin_lut[3] = 8'd218;
        sin_lut[4] = 8'd128; sin_lut[5] = 8'd37;
        sin_lut[6] = 8'd0;   sin_lut[7] = 8'd37;
    end
    
    // 阶段1: 相位累加
    always @(posedge clk) begin
        if (reset) begin
            phase_stage1 <= 8'd0;
        end else begin
            phase_stage1 <= phase_stage1 + freq_ctrl;
        end
    end
    
    // 阶段2: 提取相位高位并计算索引
    always @(posedge clk) begin
        if (reset) begin
            phase_stage2 <= 8'd0;
            phase_index_stage1 <= 3'd0;
            cos_index_stage1 <= 3'd2;
        end else begin
            phase_stage2 <= phase_stage1;
            phase_index_stage1 <= phase_stage1[7:5];
            cos_index_stage1 <= (phase_stage1[7:5] + 3'd2) % 8;
        end
    end
    
    // 阶段3: 索引传递和预处理
    always @(posedge clk) begin
        if (reset) begin
            phase_stage3 <= 8'd0;
            phase_index_stage2 <= 3'd0;
            cos_index_stage2 <= 3'd2;
        end else begin
            phase_stage3 <= phase_stage2;
            phase_index_stage2 <= phase_index_stage1;
            cos_index_stage2 <= cos_index_stage1;
        end
    end
    
    // 阶段4: 索引传递
    always @(posedge clk) begin
        if (reset) begin
            phase_stage4 <= 8'd0;
            phase_index_stage3 <= 3'd0;
            cos_index_stage3 <= 3'd2;
        end else begin
            phase_stage4 <= phase_stage3;
            phase_index_stage3 <= phase_index_stage2;
            cos_index_stage3 <= cos_index_stage2;
        end
    end
    
    // 阶段5: 查表准备
    always @(posedge clk) begin
        if (reset) begin
            phase_index_stage4 <= 3'd0;
            cos_index_stage4 <= 3'd2;
        end else begin
            phase_index_stage4 <= phase_index_stage3;
            cos_index_stage4 <= cos_index_stage3;
        end
    end
    
    // 阶段6: 查表
    always @(posedge clk) begin
        if (reset) begin
            sin_value_stage4 <= 8'd128;
            cos_value_stage4 <= 8'd255;
        end else begin
            sin_value_stage4 <= sin_lut[phase_index_stage4];
            cos_value_stage4 <= sin_lut[cos_index_stage4];
        end
    end
    
    // 阶段7: 输出寄存
    always @(posedge clk) begin
        if (reset) begin
            sine <= 8'd128;
            cosine <= 8'd255;
        end else begin
            sine <= sin_value_stage4;
            cosine <= cos_value_stage4;
        end
    end
endmodule