//SystemVerilog
module DynamicMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data,
    input load, 
    input [WIDTH-1:0] new_pattern,
    output reg match
);
    reg [WIDTH-1:0] current_pattern;
    wire pre_match;
    
    // 寄存器保存模式
    always @(posedge clk)
        if (load)
            current_pattern <= new_pattern;
    
    // 前置比较逻辑
    assign pre_match = (data == current_pattern);
    
    // 将比较结果寄存器移到组合逻辑之后
    always @(posedge clk)
        match <= pre_match;
endmodule