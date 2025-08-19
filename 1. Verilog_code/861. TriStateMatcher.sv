module TriStateMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input [WIDTH-1:0] mask, // 0=无关位
    output match
);
assign match = ((data & mask) == (pattern & mask));
endmodule
