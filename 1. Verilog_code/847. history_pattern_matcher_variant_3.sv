//SystemVerilog
module history_pattern_matcher #(parameter W = 8, DEPTH = 3) (
    input clk, rst_n,
    input [W-1:0] data_in, pattern,
    output reg seq_match
);
    reg [W-1:0] history [DEPTH-1:0];
    reg [W-1:0] data_in_reg, pattern_reg;
    wire match_result;
    integer i;
    
    // 组合逻辑计算匹配结果
    assign match_result = (data_in_reg == pattern_reg);
    
    // 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 0;
            pattern_reg <= 0;
        end else begin
            data_in_reg <= data_in;
            pattern_reg <= pattern;
        end
    end
    
    // 历史数据更新和匹配结果寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seq_match <= 0;
            for (i = 0; i < DEPTH; i = i + 1)
                history[i] <= 0;
        end else begin
            for (i = DEPTH-1; i > 0; i = i - 1)
                history[i] <= history[i-1];
            history[0] <= data_in_reg;
            seq_match <= match_result;
        end
    end
endmodule