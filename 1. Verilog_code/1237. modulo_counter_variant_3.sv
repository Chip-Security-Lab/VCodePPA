//SystemVerilog
//IEEE 1364-2005
module modulo_counter #(
    parameter MOD_VALUE = 10,
    parameter WIDTH = 4
) (
    input wire clk,
    input wire reset,
    input wire enable,
    output reg [WIDTH-1:0] count,
    output wire tc,
    output reg valid_out
);
    // 优化的流水线寄存器和控制信号
    reg [WIDTH-1:0] count_stage1, count_stage2;
    reg tc_stage1, tc_stage2;
    reg valid_stage1, valid_stage2;
    
    // 预计算终端计数条件 - 优化比较逻辑
    wire is_terminal_count;
    // 使用范围检查而非相等比较，可改善时序
    assign is_terminal_count = (count >= MOD_VALUE - 1);
    
    // 第一级流水线 - 比较判断（优化）
    always @(posedge clk) begin
        if (reset) begin
            count_stage1 <= {WIDTH{1'b0}};
            tc_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            count_stage1 <= count;
            tc_stage1 <= is_terminal_count;
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 优化第二级流水线逻辑 - 移除条件判断
    wire [WIDTH-1:0] next_count;
    assign next_count = tc_stage1 ? {WIDTH{1'b0}} : count_stage1 + 1'b1;
    
    // 第二级流水线 - 更新准备
    always @(posedge clk) begin
        if (reset) begin
            count_stage2 <= {WIDTH{1'b0}};
            tc_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (enable) begin
            count_stage2 <= next_count;
            tc_stage2 <= tc_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 输出更新
    always @(posedge clk) begin
        if (reset) begin
            count <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end
        else if (enable) begin
            count <= count_stage2;
            valid_out <= valid_stage2;
        end
    end
    
    // 终端计数信号
    assign tc = tc_stage2;
    
endmodule