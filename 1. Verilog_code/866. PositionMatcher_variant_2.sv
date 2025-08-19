//SystemVerilog
module PositionMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg [WIDTH-1:0] match_pos
);
    // 定义组合逻辑的输出信号
    wire [WIDTH-1:0] match_result;
    
    // 将比较逻辑移到寄存器前面，作为纯组合逻辑
    genvar i;
    generate
        for (i=0; i<WIDTH; i=i+1) begin : match_logic
            assign match_result[i] = (data[i] == pattern[i]);
        end
    endgenerate
    
    // 寄存器现在位于组合逻辑之后
    always @(posedge clk) begin
        match_pos <= match_result;
    end
endmodule