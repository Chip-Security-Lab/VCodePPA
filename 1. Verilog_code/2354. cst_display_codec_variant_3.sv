//SystemVerilog
module cst_display_codec #(
    parameter integer COEF_WIDTH = 8,
    parameter integer DATA_WIDTH = 8
) (
    input clk, rst_n, enable,
    input [3*DATA_WIDTH-1:0] in_color,
    input [3*3*COEF_WIDTH-1:0] transform_matrix,
    output reg [3*DATA_WIDTH-1:0] out_color,
    output reg valid
);
    // 第一级流水线寄存器 - 存储输入数据
    reg [3*DATA_WIDTH-1:0] in_color_stage1;
    reg [3*3*COEF_WIDTH-1:0] transform_matrix_stage1;
    reg enable_stage1;
    
    // 第二级流水线寄存器 - 存储乘法结果
    reg [2*DATA_WIDTH+COEF_WIDTH-1:0] mult_results_stage2 [8:0];
    reg enable_stage2;
    
    // 第三级流水线寄存器 - 存储加法结果
    reg [DATA_WIDTH+COEF_WIDTH:0] sums_stage3 [2:0];
    reg enable_stage3;
    
    // 第四级流水线寄存器 - 存储截断结果
    reg [DATA_WIDTH-1:0] clipped_stage4 [2:0];
    reg enable_stage4;
    
    // 组合逻辑计算
    wire [2*DATA_WIDTH+COEF_WIDTH-1:0] mult_results [8:0];
    wire [DATA_WIDTH+COEF_WIDTH:0] sums [2:0];
    wire [DATA_WIDTH-1:0] clipped [2:0];
    
    // 第一级流水线：Matrix multiplication乘法部分
    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : rows
            for (j = 0; j < 3; j = j + 1) begin : cols
                assign mult_results[i*3+j] = in_color_stage1[j*DATA_WIDTH +: DATA_WIDTH] * 
                                             transform_matrix_stage1[(i*3+j)*COEF_WIDTH +: COEF_WIDTH];
            end
        end
    endgenerate
    
    // 第二级流水线：计算累加
    generate
        for (i = 0; i < 3; i = i + 1) begin : sum_rows
            assign sums[i] = mult_results_stage2[i*3] + mult_results_stage2[i*3+1] + mult_results_stage2[i*3+2];
        end
    endgenerate
    
    // 第三级流水线：结果截断 - 优化比较链
    generate
        for (i = 0; i < 3; i = i + 1) begin : clip_rows
            // 优化的范围检查 - 使用更高效的比较逻辑
            // 1. 先检查负值情况（仅检查符号位）
            // 2. 使用单一比较操作检查上限
            wire is_negative = sums_stage3[i][DATA_WIDTH+COEF_WIDTH];
            wire [DATA_WIDTH+COEF_WIDTH:0] max_value = {1'b0, {DATA_WIDTH{1'b1}}};
            wire is_overflow = (sums_stage3[i] > max_value);
            
            // 使用优化的三元操作符，将判断条件重新排序
            assign clipped[i] = is_negative ? {DATA_WIDTH{1'b0}} :
                               is_overflow ? {DATA_WIDTH{1'b1}} : 
                               sums_stage3[i][DATA_WIDTH-1:0];
        end
    endgenerate
    
    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置所有流水线寄存器
            in_color_stage1 <= 0;
            transform_matrix_stage1 <= 0;
            enable_stage1 <= 0;
            
            for (int k = 0; k < 9; k = k + 1) begin
                mult_results_stage2[k] <= 0;
            end
            enable_stage2 <= 0;
            
            for (int k = 0; k < 3; k = k + 1) begin
                sums_stage3[k] <= 0;
                clipped_stage4[k] <= 0;
            end
            enable_stage3 <= 0;
            enable_stage4 <= 0;
            
            out_color <= 0;
            valid <= 0;
        end else begin
            // 第一级流水线 - 存储输入
            in_color_stage1 <= in_color;
            transform_matrix_stage1 <= transform_matrix;
            enable_stage1 <= enable;
            
            // 第二级流水线 - 存储乘法结果
            for (int k = 0; k < 9; k = k + 1) begin
                mult_results_stage2[k] <= mult_results[k];
            end
            enable_stage2 <= enable_stage1;
            
            // 第三级流水线 - 存储加法结果
            for (int k = 0; k < 3; k = k + 1) begin
                sums_stage3[k] <= sums[k];
            end
            enable_stage3 <= enable_stage2;
            
            // 第四级流水线 - 存储截断结果
            for (int k = 0; k < 3; k = k + 1) begin
                clipped_stage4[k] <= clipped[k];
            end
            enable_stage4 <= enable_stage3;
            
            // 输出寄存器
            if (enable_stage4) begin
                out_color <= {clipped_stage4[2], clipped_stage4[1], clipped_stage4[0]};
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end
endmodule