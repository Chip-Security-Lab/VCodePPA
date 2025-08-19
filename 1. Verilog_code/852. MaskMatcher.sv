module MaskMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern, mask,
    output match
);
assign match = ((data & mask) == (pattern & mask));
endmodule
