//SystemVerilog
// SystemVerilog
module PositionMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg [WIDTH-1:0] match_pos
);
    reg [WIDTH-1:0] data_reg;
    reg [WIDTH-1:0] pattern_reg;
    
    // 寄存器前移 - 将输入信号寄存
    always @(posedge clk) begin
        data_reg <= data;
        pattern_reg <= pattern;
    end
    
    // 在寄存后的数据上执行比较逻辑
    genvar i;
    generate
        for (i=0; i<WIDTH; i=i+1) begin: compare_bit
            always @(posedge clk) begin
                match_pos[i] <= (data_reg[i] == pattern_reg[i]);
            end
        end
    endgenerate
endmodule