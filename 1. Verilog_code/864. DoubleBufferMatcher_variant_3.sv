//SystemVerilog
module DoubleBufferMatcher #(parameter WIDTH=8) (
    input clk, sel_buf,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern0, pattern1,
    output reg match
);

wire [WIDTH-1:0] selected_pattern;
wire match_result;

// 使用三目运算符代替if-else语句，减少MUX级联延迟
assign selected_pattern = sel_buf ? pattern1 : pattern0;

// 将比较操作从always块移至连续赋值，可能利用更高效的比较器结构
assign match_result = (data == selected_pattern);

// 仅在寄存器中捕获比较结果
always @(match_result) begin
    match = match_result;
end

endmodule