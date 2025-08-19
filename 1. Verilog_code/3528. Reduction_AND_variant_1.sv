//SystemVerilog
//========================================================================
//========================================================================
// 顶层模块 - 8位缩位与操作的流水线实现
module Reduction_AND (
    input wire clk,         // 时钟信号
    input wire rst_n,       // 复位信号（低有效）
    input wire [7:0] data,  // 输入数据
    input wire valid_in,    // 输入有效信号
    output wire result,     // 结果输出
    output wire valid_out   // 输出有效信号
);
    // 第一级流水线 - 拆分8位数据为2位数据的与结果
    wire [3:0] stage1_results;
    wire stage1_valid;
    
    // 第二级流水线 - 拆分4个2位结果为2个2位结果的与结果
    reg [1:0] stage2_results;
    reg stage2_valid;
    
    // 第三级流水线 - 最终结果
    reg stage3_result;
    reg stage3_valid;
    
    // 第一级流水线 - 4个并行的2位缩位与操作
    assign stage1_results[0] = data[0] & data[1];
    assign stage1_results[1] = data[2] & data[3];
    assign stage1_results[2] = data[4] & data[5];
    assign stage1_results[3] = data[6] & data[7];
    assign stage1_valid = valid_in;
    
    // 第二级流水线 - 2个并行的2位缩位与操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_results <= 2'b0;
            stage2_valid <= 1'b0;
        end else begin
            stage2_results[0] <= stage1_results[0] & stage1_results[1];
            stage2_results[1] <= stage1_results[2] & stage1_results[3];
            stage2_valid <= stage1_valid;
        end
    end
    
    // 第三级流水线 - 最终缩位与操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_result <= 1'b0;
            stage3_valid <= 1'b0;
        end else begin
            stage3_result <= stage2_results[0] & stage2_results[1];
            stage3_valid <= stage2_valid;
        end
    end
    
    // 输出赋值
    assign result = stage3_result;
    assign valid_out = stage3_valid;
    
endmodule