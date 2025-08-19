//SystemVerilog
// 顶层模块
module ErrorCounter #(
    parameter WIDTH = 8,
    parameter MAX_ERR = 3
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [WIDTH-1:0] data,
    input wire [WIDTH-1:0] pattern,
    output wire alarm,
    output wire valid_out
);
    // 内部连线和流水线寄存器
    wire pattern_mismatch_stage1;
    reg  valid_stage1, valid_stage2;
    reg  [WIDTH-1:0] data_stage1, pattern_stage1;
    reg  pattern_mismatch_stage2;
    reg  [3:0] error_count;
    reg  alarm_reg;
    
    // 流水线阶段1: 数据和控制信号寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data;
            pattern_stage1 <= pattern;
            valid_stage1 <= valid_in;
        end
    end
    
    // 模式匹配检测器实例
    PatternComparator #(
        .WIDTH(WIDTH)
    ) pattern_comp_inst (
        .data(data_stage1),
        .pattern(pattern_stage1),
        .mismatch(pattern_mismatch_stage1)
    );
    
    // 流水线阶段2: 检测结果寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_mismatch_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            pattern_mismatch_stage2 <= pattern_mismatch_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 错误跟踪逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_count <= 4'b0;
            alarm_reg <= 1'b0;
        end else if (valid_stage2) begin
            // 如果检测到错误则计数增加，否则重置为0
            error_count <= pattern_mismatch_stage2 ? error_count + 1'b1 : 4'b0;
            // 当错误计数达到或超过最大错误数时触发警报
            alarm_reg <= (error_count >= MAX_ERR-1) && pattern_mismatch_stage2;
        end
    end
    
    // 输出赋值
    assign alarm = alarm_reg;
    assign valid_out = valid_stage2;
    
endmodule

// 模式比较器子模块 (纯组合逻辑)
module PatternComparator #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data,
    input wire [WIDTH-1:0] pattern,
    output wire mismatch
);
    // 当数据与模式不匹配时产生错误信号
    assign mismatch = (data != pattern);
    
endmodule