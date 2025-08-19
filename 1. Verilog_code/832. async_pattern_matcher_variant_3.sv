//SystemVerilog
module async_pattern_matcher #(
    parameter WIDTH = 8
) (
    input wire clk,               // 添加时钟输入
    input wire rst_n,             // 添加复位输入
    input wire [WIDTH-1:0] data_in, 
    input wire [WIDTH-1:0] pattern,
    input wire data_valid,        // 添加数据有效信号
    output reg match_out,         // 改为寄存器输出
    output reg match_valid        // 添加匹配结果有效信号
);
    // 流水线寄存器定义
    reg [WIDTH-1:0] data_stage1, pattern_stage1;
    reg data_valid_stage1;
    
    reg [WIDTH/2-1:0] match_upper, match_lower;
    reg match_partial_valid;
    
    // 第一级流水线 - 注册输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            data_valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            pattern_stage1 <= pattern;
            data_valid_stage1 <= data_valid;
        end
    end
    
    // 第二级流水线 - 分割比较逻辑，分别比较上半部分和下半部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_upper <= 1'b0;
            match_lower <= 1'b0;
            match_partial_valid <= 1'b0;
        end else if (data_valid_stage1) begin
            match_upper <= (data_stage1[WIDTH-1:WIDTH/2] == pattern_stage1[WIDTH-1:WIDTH/2]);
            match_lower <= (data_stage1[WIDTH/2-1:0] == pattern_stage1[WIDTH/2-1:0]);
            match_partial_valid <= data_valid_stage1;
        end else begin
            match_partial_valid <= 1'b0;
        end
    end
    
    // 第三级流水线 - 组合部分结果并输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_out <= 1'b0;
            match_valid <= 1'b0;
        end else if (match_partial_valid) begin
            match_out <= match_upper & match_lower;
            match_valid <= 1'b1;
        end else begin
            match_valid <= 1'b0;
        end
    end
    
endmodule