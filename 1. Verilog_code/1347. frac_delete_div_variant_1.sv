//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// 小数分频器顶层模块 - 优化数据流结构
///////////////////////////////////////////////////////////////////////////////
module frac_delete_div #(
    parameter ACC_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    output wire clk_out
);

    // 流水线阶段信号定义
    reg  [ACC_WIDTH-1:0] accumulator_stage1;
    reg  [ACC_WIDTH-1:0] accumulator_stage2;
    wire                 threshold_result;
    reg                  threshold_result_reg;
    
    // 增量值常量，3/2^8 = 0.01171875，约等于输出频率为输入的0.75倍
    localparam [ACC_WIDTH-1:0] INCREMENT_VALUE = 'd3;
    // 比较阈值常量
    localparam [ACC_WIDTH-1:0] THRESHOLD_VALUE = 8'h80;  // 128

    // 第一阶段：累加器逻辑 - 流水线阶段1
    always @(posedge clk) begin
        if (rst) begin
            accumulator_stage1 <= {ACC_WIDTH{1'b0}};
        end else begin
            accumulator_stage1 <= accumulator_stage1 + INCREMENT_VALUE;
        end
    end
    
    // 中间寄存器阶段 - 流水线阶段2
    // 将长路径切分，减少时序关键路径
    always @(posedge clk) begin
        if (rst) begin
            accumulator_stage2 <= {ACC_WIDTH{1'b0}};
        end else begin
            accumulator_stage2 <= accumulator_stage1;
        end
    end

    // 第二阶段：阈值比较逻辑 - 组合逻辑部分
    assign threshold_result = (accumulator_stage2 < THRESHOLD_VALUE);
    
    // 比较结果寄存 - 流水线阶段3
    always @(posedge clk) begin
        if (rst) begin
            threshold_result_reg <= 1'b0;
        end else begin
            threshold_result_reg <= threshold_result;
        end
    end
    
    // 第三阶段：输出生成 - 最终输出阶段
    // 使用寄存输出，提高时序裕量
    reg clk_out_reg;
    always @(posedge clk) begin
        if (rst) begin
            clk_out_reg <= 1'b0;
        end else begin
            clk_out_reg <= threshold_result_reg;
        end
    end
    
    // 输出赋值
    assign clk_out = clk_out_reg;

endmodule