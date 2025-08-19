//SystemVerilog
module SobelEdge #(parameter W=8) (
    input clk,
    input rst,
    input valid_in,
    input [W-1:0] pixel_in,
    output valid_out,
    output [W+1:0] gradient
);
    // 窗口寄存器
    reg [W-1:0] window [0:8];
    
    // 提前计算的信号
    wire [W+1:0] left_sum_pre;
    wire [W+1:0] right_sum_pre;
    wire [W+1:0] gradient_pre;
    
    // 流水线阶段1：窗口移位和直接部分计算
    reg valid_stage1;
    reg [W+1:0] sum_left_stage1;
    reg [W+1:0] sum_right_stage1;
    
    // 流水线阶段2：最终梯度计算
    reg [W+1:0] gradient_reg;
    reg valid_stage2;
    
    integer i;
    
    // 提前计算组合逻辑
    assign left_sum_pre = window[0] + (window[3] << 1) + window[6];
    assign right_sum_pre = window[2] + (window[5] << 1) + window[8];
    assign gradient_pre = left_sum_pre - right_sum_pre;
    
    // 阶段1：窗口移位并直接计算部分和
    always @(posedge clk) begin
        if (rst) begin
            for(i=0; i<9; i=i+1)
                window[i] <= 0;
            valid_stage1 <= 0;
            sum_left_stage1 <= 0;
            sum_right_stage1 <= 0;
        end
        else begin
            // 移位窗口
            if (valid_in) begin
                for(i=8; i>0; i=i-1)
                    window[i] <= window[i-1];
                window[0] <= pixel_in;
                
                // 直接寄存部分和计算结果
                sum_left_stage1 <= left_sum_pre;
                sum_right_stage1 <= right_sum_pre;
            end
            
            valid_stage1 <= valid_in;
        end
    end
    
    // 阶段2：梯度计算
    always @(posedge clk) begin
        if (rst) begin
            gradient_reg <= 0;
            valid_stage2 <= 0;
        end
        else begin
            if (valid_stage1) begin
                // 使用已计算的部分和计算梯度
                gradient_reg <= sum_left_stage1 - sum_right_stage1;
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign gradient = gradient_reg;
    assign valid_out = valid_stage2;
    
endmodule