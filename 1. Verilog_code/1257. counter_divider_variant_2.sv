//SystemVerilog - IEEE 1364-2005
module counter_divider #(parameter RATIO=10) (
    input clk, rst,
    output reg clk_out
);
    // 计数器寄存器
    reg [$clog2(RATIO)-1:0] cnt_stage1;
    
    // 优化流水线级数的中间状态寄存器
    reg compare_result_stage2; // 比较结果的流水线寄存器
    reg [$clog2(RATIO)-1:0] next_cnt_stage1; // 下一个计数值的流水线寄存器
    
    // 优化的加法器信号
    wire [$clog2(RATIO)-1:0] add_result;
    
    // 常量定义 - 提高可读性并允许逻辑优化
    localparam MAX_COUNT = RATIO - 1;
    
    // 高效加法器实现
    assign add_result = cnt_stage1 + 1'b1;
    
    // 优化比较逻辑 - 使用并行比较结构替代串行比较链
    always @(*) begin
        // 范围检查优化 - 使用单次比较
        if (cnt_stage1 == MAX_COUNT)
            next_cnt_stage1 = '0;
        else
            next_cnt_stage1 = add_result;
    end
    
    // 更新计数器和流水线寄存器
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage1 <= '0;
            compare_result_stage2 <= 1'b0;
        end else begin
            cnt_stage1 <= next_cnt_stage1;
            compare_result_stage2 <= (cnt_stage1 == MAX_COUNT);
        end
    end
    
    // 更新输出时钟
    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (compare_result_stage2) begin
            clk_out <= ~clk_out;
        end
    end
endmodule