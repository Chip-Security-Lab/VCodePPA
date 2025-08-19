//SystemVerilog
module history_pattern_matcher #(parameter W = 8, DEPTH = 3) (
    input clk, rst_n,
    input [W-1:0] data_in, pattern,
    output reg seq_match
);
    reg [W-1:0] history [DEPTH-1:0];
    wire [W-1:0] pattern_complement;
    wire [W-1:0] comparison_result;
    wire is_match;
    integer i;
    
    // 生成模式的补码（按位取反加1）
    assign pattern_complement = ~pattern + 1'b1;
    
    // 使用补码加法实现比较运算
    assign comparison_result = history[0] + pattern_complement;
    // 如果结果为0，表示匹配
    assign is_match = (comparison_result == {W{1'b0}});
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                history[i] <= 0;
            seq_match <= 0;
        end else begin
            // Shift history register
            for (i = DEPTH-1; i > 0; i = i - 1)
                history[i] <= history[i-1];
            history[0] <= data_in;
            
            // 使用补码加法比较结果更新匹配状态
            seq_match <= is_match;
        end
    end
endmodule