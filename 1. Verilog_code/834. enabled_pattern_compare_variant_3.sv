//SystemVerilog
module enabled_pattern_compare #(parameter DWIDTH = 16) (
    input clk, rst_n, en,
    input [DWIDTH-1:0] in_data, in_pattern,
    output reg match
);
    // 预先计算比较结果，减少关键路径
    wire compare_result;
    
    // 使用异或门和归约操作符优化比较
    assign compare_result = ~|(in_data ^ in_pattern);
    
    // 增加比较寄存器以提高时序性能
    reg pre_match;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pre_match <= 1'b0;
            match <= 1'b0;
        end else begin
            pre_match <= compare_result;
            if (en)
                match <= pre_match;
        end
    end
endmodule