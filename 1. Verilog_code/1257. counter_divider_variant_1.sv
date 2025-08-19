//SystemVerilog
//IEEE 1364-2005 Verilog标准
module counter_divider #(parameter RATIO=10) (
    input wire clk,
    input wire rst,
    output reg clk_out
);
    // 使用常量来减少比较运算符消耗
    localparam CNT_WIDTH = $clog2(RATIO);
    localparam RATIO_M1 = RATIO-1;

    // 流水线阶段1：计数器和边界检测
    reg [CNT_WIDTH-1:0] cnt_stage1;
    reg compare_result_stage1;
    
    // 流水线阶段2：时钟输出切换控制
    reg toggle_enable_stage2;
    
    // 阶段1：优化的计数和比较
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage1 <= {CNT_WIDTH{1'b0}};
            compare_result_stage1 <= 1'b0;
        end else begin
            // 优化的比较逻辑：使用相等比较而不是条件执行
            compare_result_stage1 <= (cnt_stage1 == RATIO_M1);
            // 优化的计数器更新逻辑
            cnt_stage1 <= (cnt_stage1 == RATIO_M1) ? {CNT_WIDTH{1'b0}} : cnt_stage1 + 1'b1;
        end
    end
    
    // 阶段2：切换使能传播
    always @(posedge clk) begin
        if (rst) begin
            toggle_enable_stage2 <= 1'b0;
        end else begin
            toggle_enable_stage2 <= compare_result_stage1;
        end
    end
    
    // 输出时钟生成 - 使用阻塞赋值来优化逻辑路径
    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (toggle_enable_stage2) begin
            clk_out <= ~clk_out;
        end
    end
endmodule