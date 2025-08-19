//SystemVerilog
module counter_divider #(parameter RATIO=10) (
    input clk, rst,
    output reg clk_out
);
    reg [$clog2(RATIO)-1:0] cnt;
    reg next_clk_out;
    
    // 查找表 - 用于比较操作
    reg [$clog2(RATIO)-1:0] compare_lut [0:1];
    reg is_max_count;
    
    // 初始化查找表
    initial begin
        compare_lut[0] = RATIO-1;
        compare_lut[1] = 0;
    end
    
    // 使用查找表辅助的比较逻辑
    always @(*) begin
        is_max_count = (cnt == compare_lut[0]);
        next_clk_out = clk_out;
        if (is_max_count) begin
            next_clk_out = ~clk_out;
        end
    end
    
    // cnt计数逻辑
    always @(posedge clk) begin
        if (rst) begin
            cnt <= compare_lut[1];
            clk_out <= 0;
        end else begin
            if (is_max_count) begin
                cnt <= compare_lut[1];
            end else begin
                cnt <= cnt + 1;
            end
            clk_out <= next_clk_out;
        end
    end
endmodule