//SystemVerilog
module sync_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    output reg match_out
);
    reg [WIDTH-1:0] data_reg;
    reg [WIDTH-1:0] pattern_reg;
    reg match_result;
    
    // 存储输入数据和模式以减少比较时的关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {WIDTH{1'b0}};
            pattern_reg <= {WIDTH{1'b0}};
        end else begin
            data_reg <= data_in;
            pattern_reg <= pattern;
        end
    end
    
    // 优化比较逻辑，使用组合逻辑计算结果
    always @(*) begin
        match_result = (data_reg == pattern_reg);
    end
    
    // 寄存比较结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_out <= 1'b0;
        else
            match_out <= match_result;
    end
endmodule