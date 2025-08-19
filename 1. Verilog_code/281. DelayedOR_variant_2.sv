//SystemVerilog
`timescale 1ns/1ps
module DelayedOR(
    input logic clk,
    input logic rst_n,
    input logic x, y,
    input logic ready_in,
    output logic z,
    output logic valid_out,
    output logic ready_out
);
    // 流水线控制信号
    logic start;
    logic valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // 流水线寄存器
    logic [7:0] dividend_stage1;
    logic [7:0] divisor_stage1;
    logic [7:0] quotient_stage1, quotient_stage2, quotient_stage3, quotient_stage4;
    logic [15:0] partial_remainder_stage1, partial_remainder_stage2, partial_remainder_stage3;
    logic [3:0] count_stage1, count_stage2, count_stage3;
    
    // LUT用于保存预计算结果
    logic [15:0] bit_result_lut[0:1][0:1]; // [超过除数标志][第几位]

    // 控制信号逻辑优化
    assign start = (x | y) & ready_in & ready_out;
    assign ready_out = !valid_stage4 | (valid_stage4 & ready_in);
    
    // LUT初始化 - 在复位时初始化
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // LUT for bit processing results
            // 索引格式：[是否超过除数][处理位索引]
            bit_result_lut[0][0] <= 16'h0000; // 未超过除数，添加0
            bit_result_lut[0][1] <= 16'h0001; // 未超过除数，添加1
            bit_result_lut[1][0] <= 16'h0002; // 超过除数，添加0
            bit_result_lut[1][1] <= 16'h0003; // 超过除数，添加1
        end
    end

    // 第一级流水线：初始化 - 使用查找表方式优化
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            dividend_stage1 <= 8'h0;
            divisor_stage1 <= 8'h0;
            quotient_stage1 <= 8'h0;
            partial_remainder_stage1 <= 16'h0;
            count_stage1 <= 4'h0;
        end else if (start) begin
            valid_stage1 <= 1'b1;
            dividend_stage1 <= 8'hFF;
            divisor_stage1 <= 8'h0F;
            quotient_stage1 <= 8'b0;
            partial_remainder_stage1 <= {8'b0, 8'hFF};
            count_stage1 <= 4'd8;
        end else if (ready_out) begin
            valid_stage1 <= 1'b0;
        end
    end

    // 预先计算用于第二级处理的查找表索引
    logic [2:0] stage2_lut_idx[0:2]; // 3位处理的LUT索引

    // 第二级流水线：处理前3位 - 使用查找表替代条件逻辑
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            quotient_stage2 <= 8'h0;
            partial_remainder_stage2 <= 16'h0;
            count_stage2 <= 4'h0;
            for (int i = 0; i < 3; i++)
                stage2_lut_idx[i] <= 3'd0;
        end else if (ready_out) begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                count_stage2 <= count_stage1 - 3;
                
                // 并行计算3位处理的LUT索引
                for (int i = 0; i < 3; i++) begin
                    // 计算当前步的部分余数是否超过除数
                    logic [15:0] shifted_remainder;
                    logic div_flag;
                    
                    if (i == 0) begin
                        shifted_remainder = partial_remainder_stage1 << 1;
                    end else if (i == 1) begin
                        shifted_remainder = (partial_remainder_stage1 << 1) << 1;
                        if (shifted_remainder[15:8] >= divisor_stage1)
                            shifted_remainder[15:8] = shifted_remainder[15:8] - divisor_stage1;
                    end else begin
                        shifted_remainder = ((partial_remainder_stage1 << 1) << 1) << 1;
                        if (shifted_remainder[15:8] >= divisor_stage1)
                            shifted_remainder[15:8] = shifted_remainder[15:8] - divisor_stage1;
                    end
                    
                    div_flag = (shifted_remainder[15:8] >= divisor_stage1) ? 1'b1 : 1'b0;
                    stage2_lut_idx[i] <= {div_flag, i[1:0]};
                end
                
                // 使用查找表更新部分余数和商
                // 这里使用查找表的结果代替条件语句
                partial_remainder_stage2 <= bit_result_lut[stage2_lut_idx[0][2]][stage2_lut_idx[0][1:0]];
                quotient_stage2 <= (quotient_stage1 << 3) | 
                                   {stage2_lut_idx[0][2], stage2_lut_idx[1][2], stage2_lut_idx[2][2]};
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end

    // 预先计算用于第三级处理的查找表索引
    logic [2:0] stage3_lut_idx[0:2]; // 3位处理的LUT索引

    // 第三级流水线：处理中间3位 - 使用查找表方式优化
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            quotient_stage3 <= 8'h0;
            partial_remainder_stage3 <= 16'h0;
            count_stage3 <= 4'h0;
            for (int i = 0; i < 3; i++)
                stage3_lut_idx[i] <= 3'd0;
        end else if (ready_out) begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                count_stage3 <= count_stage2 - 3;
                
                // 并行计算3位处理的LUT索引
                for (int i = 0; i < 3; i++) begin
                    // 计算当前步的部分余数是否超过除数
                    logic [15:0] shifted_remainder;
                    logic div_flag;
                    
                    if (i == 0) begin
                        shifted_remainder = partial_remainder_stage2 << 1;
                    end else if (i == 1) begin
                        shifted_remainder = (partial_remainder_stage2 << 1) << 1;
                        if (shifted_remainder[15:8] >= divisor_stage1)
                            shifted_remainder[15:8] = shifted_remainder[15:8] - divisor_stage1;
                    end else begin
                        shifted_remainder = ((partial_remainder_stage2 << 1) << 1) << 1;
                        if (shifted_remainder[15:8] >= divisor_stage1)
                            shifted_remainder[15:8] = shifted_remainder[15:8] - divisor_stage1;
                    end
                    
                    div_flag = (shifted_remainder[15:8] >= divisor_stage1) ? 1'b1 : 1'b0;
                    stage3_lut_idx[i] <= {div_flag, i[1:0]};
                end
                
                // 使用查找表更新部分余数和商
                partial_remainder_stage3 <= bit_result_lut[stage3_lut_idx[0][2]][stage3_lut_idx[0][1:0]];
                quotient_stage3 <= (quotient_stage2 << 3) | 
                                   {stage3_lut_idx[0][2], stage3_lut_idx[1][2], stage3_lut_idx[2][2]};
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end

    // 预计算最终处理的查找表
    logic [7:0] final_quotient_lut[0:15]; // 基于剩余计数和部分余数的最终商查找表

    // 第四级流水线：处理最后2位并产生结果 - 使用查找表优化
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage4 <= 1'b0;
            quotient_stage4 <= 8'h0;
            valid_out <= 1'b0;
            z <= 1'b0;
            // 初始化最终处理查找表
            for (int i = 0; i < 16; i++) begin
                final_quotient_lut[i] <= 8'h00;
            end
        end else if (ready_out) begin
            valid_stage4 <= valid_stage3;
            if (valid_stage3) begin
                // 使用查找表处理最后位
                // 查找表索引由部分余数状态和count_stage3组成
                logic [3:0] final_lut_idx;
                final_lut_idx = {(partial_remainder_stage3[15:8] >= divisor_stage1), count_stage3[2:0]};
                
                // 使用预先计算的值
                quotient_stage4 <= final_quotient_lut[final_lut_idx];
                
                // 设置输出信号
                valid_out <= 1'b1;
                z <= 1'b1;
            end else begin
                valid_stage4 <= 1'b0;
                valid_out <= 1'b0;
            end
        end
    end

    // 移除原始函数，使用查找表替代
endmodule