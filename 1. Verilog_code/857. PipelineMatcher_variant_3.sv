//SystemVerilog
module PipelineMatcher #(parameter WIDTH=8) (
    input clk, 
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern,
    output reg match
);
    // 寄存器移到组合逻辑之前，对输入数据进行寄存
    reg [WIDTH-1:0] data_in_reg;
    reg [WIDTH-1:0] pattern_reg;
    
    always @(posedge clk) begin
        data_in_reg <= data_in;
        pattern_reg <= pattern;
    end
    
    // 比较逻辑现在使用已寄存的输入数据
    // 输出直接连接到组合逻辑结果，不再有输出寄存器
    assign match = (data_in_reg == pattern_reg);
endmodule