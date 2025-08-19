module DoubleBufferMatcher #(parameter WIDTH=8) (
    input clk, sel_buf,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern0, pattern1,
    output match
);
assign match = sel_buf ? (data == pattern1) : (data == pattern0);
endmodule
