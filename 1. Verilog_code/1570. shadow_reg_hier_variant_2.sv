//SystemVerilog
module shadow_reg_hier #(parameter DW=16) (
    input clk, main_en, sub_en,
    input [DW-1:0] main_data,
    output [DW-1:0] final_data
);
    // 主要流水线寄存器
    reg [DW-1:0] main_shadow_stage1, main_shadow_stage2, main_shadow_stage3;
    reg [DW-1:0] sub_shadow_stage1, sub_shadow_stage2, sub_shadow_stage3;
    
    // 查找表拆分为两个较小的查找表，降低单周期查找的复杂度
    reg [7:0] subtractor_lut_high [0:255]; // 高8位查找表
    reg [7:0] subtractor_lut_low [0:255];  // 低8位查找表
    
    // 流水线操作寄存器
    reg [7:0] operand_a_stage1, operand_a_stage2;
    reg [7:0] operand_b_stage1, operand_b_stage2;
    reg [7:0] subtract_result_stage1, subtract_result_stage2, subtract_result_final;
    
    // 流水线控制信号
    reg perform_subtract_stage1, perform_subtract_stage2, perform_subtract_stage3;
    reg sub_en_stage1, sub_en_stage2, main_en_stage1;
    
    // 初始化查找表 - 将大查找表拆分为两个较小的表
    integer i, j;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            subtractor_lut_high[i] = i;
            for (j = 0; j < 256; j = j + 1) begin
                if (j == 0) subtractor_lut_low[i] = i; // 当j=0时，结果就是i
                else subtractor_lut_low[(i-j) & 8'hFF] = i - j; // 存储所有可能的减法结果
            end
        end
    end
    
    // 流水线阶段1 - 输入采样和初始操作准备
    always @(posedge clk) begin
        // 控制信号寄存
        main_en_stage1 <= main_en;
        sub_en_stage1 <= sub_en;
        
        // 数据采样
        if (main_en) begin
            main_shadow_stage1 <= main_data;
            operand_a_stage1 <= main_data[7:0];
            perform_subtract_stage1 <= 1'b1;
        end else begin
            perform_subtract_stage1 <= 1'b0;
        end
        
        if (sub_en) begin
            operand_b_stage1 <= main_shadow_stage3[7:0];
        end
    end
    
    // 流水线阶段2 - 查找表预处理
    always @(posedge clk) begin
        // 更新控制信号
        perform_subtract_stage2 <= perform_subtract_stage1;
        sub_en_stage2 <= sub_en_stage1;
        
        // 数据传递
        main_shadow_stage2 <= main_shadow_stage1;
        operand_a_stage2 <= operand_a_stage1;
        operand_b_stage2 <= operand_b_stage1;
        
        // 查找表第一阶段处理
        if (perform_subtract_stage1) begin
            subtract_result_stage1 <= subtractor_lut_high[operand_a_stage1];
        end
    end
    
    // 流水线阶段3 - 减法操作完成
    always @(posedge clk) begin
        // 更新控制信号
        perform_subtract_stage3 <= perform_subtract_stage2;
        
        // 数据传递
        main_shadow_stage3 <= main_shadow_stage2;
        
        // 查找表第二阶段处理
        if (perform_subtract_stage2) begin
            subtract_result_stage2 <= subtractor_lut_low[operand_b_stage2];
        end
        
        // 更新子寄存器
        if (sub_en_stage2) begin
            sub_shadow_stage1 <= main_shadow_stage3;
        end
    end
    
    // 流水线阶段4 - 结果处理和输出
    always @(posedge clk) begin
        // 最终数据合并
        if (perform_subtract_stage3) begin
            subtract_result_final <= subtract_result_stage2 - subtract_result_stage1;
        end
        
        // 最终数据输出
        sub_shadow_stage2 <= sub_shadow_stage1;
        sub_shadow_stage3 <= sub_shadow_stage2;
    end
    
    // 最终输出结果
    assign final_data = sub_shadow_stage3;
endmodule