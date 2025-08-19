//SystemVerilog
module async_pattern_matcher #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] pattern,
    input wire data_valid,
    output reg match_out,
    output reg match_valid
);
    // 数据流水线寄存器
    reg [WIDTH-1:0] data_stage1, pattern_stage1;
    reg data_valid_stage1;
    
    // 比较结果的流水线寄存器
    reg match_result;
    
    // 第一级流水线 - 输入寄存
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
    
    // 第二级流水线 - 比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_result <= 1'b0;
            match_valid <= 1'b0;
        end else begin
            match_result <= (data_stage1 == pattern_stage1);
            match_valid <= data_valid_stage1;
        end
    end
    
    // 第三级流水线 - 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_out <= 1'b0;
        end else begin
            match_out <= match_result;
        end
    end
    
endmodule