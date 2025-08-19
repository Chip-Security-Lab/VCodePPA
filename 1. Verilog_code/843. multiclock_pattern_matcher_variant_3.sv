//SystemVerilog
module multiclock_pattern_matcher #(parameter W = 8) (
    input clk_in, clk_out, rst_n,
    input [W-1:0] data, pattern,
    output reg match_out
);
    // 内部信号声明
    reg match_in_domain;
    reg match_in_domain_meta;
    
    // 输入时钟域 - 模式检测逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            match_in_domain <= 1'b0;
        else
            match_in_domain <= (data == pattern);
    end
    
    // 输出时钟域 - 亚稳态防护逻辑
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n)
            match_in_domain_meta <= 1'b0;
        else
            match_in_domain_meta <= match_in_domain;
    end
    
    // 输出时钟域 - 输出寄存逻辑
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n)
            match_out <= 1'b0;
        else
            match_out <= match_in_domain_meta;
    end
endmodule