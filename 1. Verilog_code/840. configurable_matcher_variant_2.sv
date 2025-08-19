//SystemVerilog
module configurable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input [1:0] mode,
    output reg result
);
    // 预计算所有比较结果
    wire is_equal = (data == pattern);
    wire is_greater = (data > pattern);
    
    // 组合逻辑，使用预计算的值实现更高效的比较
    wire next_result;
    
    assign next_result = (mode == 2'b00) ? is_equal :
                        (mode == 2'b01) ? is_greater :
                        (mode == 2'b10) ? (~is_equal & ~is_greater) :
                        (mode == 2'b11) ? ~is_equal : 1'b0;
    
    // 寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 1'b0;
        else
            result <= next_result;
    end
endmodule