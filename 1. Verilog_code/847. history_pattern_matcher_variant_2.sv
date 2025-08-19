//SystemVerilog
module history_pattern_matcher #(parameter W = 8, DEPTH = 3) (
    input clk, rst_n,
    input [W-1:0] data_in, pattern,
    output reg seq_match
);
    reg [W-1:0] history [DEPTH-1:0];
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        // 使用条件运算符替代if-else结构
        seq_match <= !rst_n ? 1'b0 : (data_in == pattern);
        
        // 历史寄存器移位操作
        for (i = DEPTH-1; i > 0; i = i - 1)
            history[i] <= !rst_n ? {W{1'b0}} : history[i-1];
        
        // 更新第一个历史寄存器
        history[0] <= !rst_n ? {W{1'b0}} : data_in;
    end
endmodule