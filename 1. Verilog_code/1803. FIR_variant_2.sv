//SystemVerilog
module FIR #(parameter W=8) (
    input clk,
    input reset,  // 添加复位信号
    input valid_in,  // 输入有效信号
    input [W-1:0] sample,
    output reg valid_out,  // 输出有效信号
    output reg [W+3:0] y
);
    // 定义系数作为单独参数
    parameter [3:0] COEFFS = 4'hA;
    
    // 延迟线寄存器
    reg [W-1:0] delay_line [0:3];
    
    // 流水线阶段寄存器 - 增加中间流水线级
    reg [W-1:0] sample_stage1; // 采样输入寄存器
    reg [W-1:0] mult_input_stage1 [0:3]; // 乘法输入寄存器
    reg [W+1:0] mult_stage2 [0:3];  // 乘法结果寄存器
    reg [W+1:0] mult_stage3 [0:3];  // 乘法结果进一步流水线
    reg [W+2:0] add_stage4_0, add_stage4_1;  // 第一级加法结果
    reg [W+2:0] add_stage5_0, add_stage5_1;  // 加法结果流水线
    reg [W+3:0] pre_y;  // 最终结果前一级
    
    // 控制信号流水线 - 增加对应级数
    reg valid_stage1, valid_stage2, valid_stage3;
    reg valid_stage4, valid_stage5, valid_stage6;
    
    integer i;
    
    always @(posedge clk) begin
        if (reset) begin
            // 复位所有寄存器
            for(i=0; i<4; i=i+1)
                delay_line[i] <= 0;
                
            sample_stage1 <= 0;
            
            for(i=0; i<4; i=i+1)
                mult_input_stage1[i] <= 0;
                
            for(i=0; i<4; i=i+1)
                mult_stage2[i] <= 0;
                
            for(i=0; i<4; i=i+1)
                mult_stage3[i] <= 0;
                
            add_stage4_0 <= 0;
            add_stage4_1 <= 0;
            add_stage5_0 <= 0;
            add_stage5_1 <= 0;
            pre_y <= 0;
            y <= 0;
            
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_stage3 <= 0;
            valid_stage4 <= 0;
            valid_stage5 <= 0;
            valid_stage6 <= 0;
            valid_out <= 0;
        end
        else begin
            // 第0级：缓存输入样本
            sample_stage1 <= sample;
            valid_stage1 <= valid_in;
            
            // 第1级：更新延迟线
            if (valid_stage1) begin
                for(i=3; i>0; i=i-1)
                    delay_line[i] <= delay_line[i-1];
                delay_line[0] <= sample_stage1;
            end
            
            // 缓存乘法输入，为下一级准备
            for(i=0; i<4; i=i+1)
                mult_input_stage1[i] <= delay_line[i];
            valid_stage2 <= valid_stage1;
            
            // 第2级：计算乘法 - 第一级
            mult_stage2[0] <= mult_input_stage1[0] * COEFFS[0];
            mult_stage2[1] <= mult_input_stage1[1] * COEFFS[1];
            mult_stage2[2] <= mult_input_stage1[2] * COEFFS[2];
            mult_stage2[3] <= mult_input_stage1[3] * COEFFS[3];
            valid_stage3 <= valid_stage2;
            
            // 第3级：乘法流水线 - 第二级 (进一步降低关键路径)
            for(i=0; i<4; i=i+1)
                mult_stage3[i] <= mult_stage2[i];
            valid_stage4 <= valid_stage3;
            
            // 第4级：第一阶段加法，将4个乘法结果分成2组进行加法
            add_stage4_0 <= mult_stage3[0] + mult_stage3[1];
            add_stage4_1 <= mult_stage3[2] + mult_stage3[3];
            valid_stage5 <= valid_stage4;
            
            // 第5级：加法流水线 - 进一步降低关键路径
            add_stage5_0 <= add_stage4_0;
            add_stage5_1 <= add_stage4_1;
            valid_stage6 <= valid_stage5;
            
            // 第6级：最终加法的第一部分
            pre_y <= add_stage5_0 + add_stage5_1;
            valid_out <= valid_stage6;
            
            // 第7级：最终结果
            y <= pre_y;
        end
    end
endmodule