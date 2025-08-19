//SystemVerilog
// 顶层模块
module moving_avg_filter #(
    parameter DATA_W = 8,
    parameter DEPTH = 4,
    parameter LOG2_DEPTH = 2  // log2(DEPTH)
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    output wire [DATA_W-1:0] data_o
);
    // 管道化数据流信号
    wire [DATA_W-1:0] data_i_reg;
    wire [DATA_W-1:0] samples [DEPTH-1:0];
    wire [DATA_W+LOG2_DEPTH-1:0] partial_sum_stage1;
    wire [DATA_W+LOG2_DEPTH-1:0] partial_sum_stage2;
    wire [DATA_W+LOG2_DEPTH-1:0] sum_result;
    wire [DATA_W-1:0] avg_result;
    
    // 输入寄存器 - 提高输入路径稳定性
    input_register #(
        .DATA_W(DATA_W)
    ) input_reg_unit (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .data_i(data_i),
        .data_o(data_i_reg)
    );
    
    // 样本移位寄存器 - 优化存储结构
    sample_shift_manager #(
        .DATA_W(DATA_W),
        .DEPTH(DEPTH)
    ) shift_unit (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .data_i(data_i_reg),
        .samples_o(samples)
    );
    
    // 分级求和器 - 改善求和逻辑时序路径
    pipelined_sum_calculator #(
        .DATA_W(DATA_W),
        .DEPTH(DEPTH),
        .LOG2_DEPTH(LOG2_DEPTH)
    ) sum_unit (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .data_i(data_i_reg),
        .samples_i(samples),
        .partial_sum_stage1_o(partial_sum_stage1),
        .partial_sum_stage2_o(partial_sum_stage2),
        .sum_o(sum_result)
    );
    
    // 平均值计算单元 - 分离除法操作
    average_calculator #(
        .DATA_W(DATA_W),
        .LOG2_DEPTH(LOG2_DEPTH)
    ) avg_unit (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .sum_i(sum_result),
        .avg_o(avg_result)
    );
    
    // 输出寄存器 - 提高输出路径稳定性
    output_register #(
        .DATA_W(DATA_W)
    ) output_reg_unit (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .data_i(avg_result),
        .data_o(data_o)
    );
endmodule

// 输入寄存器模块 - 隔离输入时序路径
module input_register #(
    parameter DATA_W = 8
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    output reg [DATA_W-1:0] data_o
);
    always @(posedge clk) begin
        if (!reset_n) begin
            data_o <= 0;
        end else if (enable) begin
            data_o <= data_i;
        end
    end
endmodule

// 样本移位寄存器管理模块 - 优化结构提高清晰度
module sample_shift_manager #(
    parameter DATA_W = 8,
    parameter DEPTH = 4
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    output reg [DATA_W-1:0] samples_o [DEPTH-1:0]
);
    integer i;
    
    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                samples_o[i] <= 0;
        end else if (enable) begin
            // 优化移位逻辑以降低逻辑深度
            samples_o[0] <= data_i;
            for (i = 1; i < DEPTH; i = i + 1)
                samples_o[i] <= samples_o[i-1];
        end
    end
endmodule

// 优化的流水线求和计算模块 - 分解求和路径减少关键路径延迟
module pipelined_sum_calculator #(
    parameter DATA_W = 8,
    parameter DEPTH = 4,
    parameter LOG2_DEPTH = 2
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    input wire [DATA_W-1:0] samples_i [DEPTH-1:0],
    output reg [DATA_W+LOG2_DEPTH-1:0] partial_sum_stage1_o,
    output reg [DATA_W+LOG2_DEPTH-1:0] partial_sum_stage2_o,
    output reg [DATA_W+LOG2_DEPTH-1:0] sum_o
);
    // 内部流水线寄存器
    reg [DATA_W+LOG2_DEPTH-1:0] oldest_sample_reg;
    reg [DATA_W-1:0] newest_sample_reg;
    
    // 第一级流水线：缓存输入和计算增量
    always @(posedge clk) begin
        if (!reset_n) begin
            oldest_sample_reg <= 0;
            newest_sample_reg <= 0;
        end else if (enable) begin
            oldest_sample_reg <= samples_i[DEPTH-1];
            newest_sample_reg <= data_i;
        end
    end
    
    // 第二级流水线：计算部分和（第一阶段）
    always @(posedge clk) begin
        if (!reset_n) begin
            partial_sum_stage1_o <= 0;
        end else if (enable) begin
            partial_sum_stage1_o <= sum_o - oldest_sample_reg;
        end
    end
    
    // 第三级流水线：计算部分和（第二阶段）
    always @(posedge clk) begin
        if (!reset_n) begin
            partial_sum_stage2_o <= 0;
        end else if (enable) begin
            partial_sum_stage2_o <= partial_sum_stage1_o + newest_sample_reg;
        end
    end
    
    // 最终求和结果
    always @(posedge clk) begin
        if (!reset_n) begin
            sum_o <= 0;
        end else if (enable) begin
            sum_o <= partial_sum_stage2_o;
        end
    end
endmodule

// 平均值计算模块 - 专注于除法操作
module average_calculator #(
    parameter DATA_W = 8,
    parameter LOG2_DEPTH = 2
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W+LOG2_DEPTH-1:0] sum_i,
    output reg [DATA_W-1:0] avg_o
);
    // 实现除法运算（通过右移实现）
    always @(posedge clk) begin
        if (!reset_n) begin
            avg_o <= 0;
        end else if (enable) begin
            avg_o <= sum_i >> LOG2_DEPTH;
        end
    end
endmodule

// 输出寄存器模块 - 隔离输出时序路径
module output_register #(
    parameter DATA_W = 8
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    output reg [DATA_W-1:0] data_o
);
    always @(posedge clk) begin
        if (!reset_n) begin
            data_o <= 0;
        end else if (enable) begin
            data_o <= data_i;
        end
    end
endmodule