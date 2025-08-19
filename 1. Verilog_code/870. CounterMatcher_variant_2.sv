//SystemVerilog
module CounterMatcher #(parameter WIDTH=8) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg [15:0] match_count
);
    // 使用寄存器预计算比较结果，减少关键路径
    reg match_flag;
    
    // 使用补码加法实现减法算法，优化比较逻辑
    wire [WIDTH:0] diff_result;
    wire [WIDTH-1:0] pattern_comp;
    
    // 计算pattern的补码
    assign pattern_comp = ~pattern + 1'b1;
    
    // 使用补码加法实现减法
    assign diff_result = {1'b0, data} + {1'b0, pattern_comp};
    
    // 预计算比较结果以减少时序关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_flag <= 1'b0;
        else
            match_flag <= (diff_result == 0); // 当差为0时表示相等
    end
    
    // 使用流水线方式更新计数器，减少逻辑层级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_count <= 16'b0;
        else if (match_flag)
            match_count <= match_count + 1'b1;
    end
endmodule