module DynMaskMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input [WIDTH-1:0] dynamic_mask,
    output match
);
assign match = ((data & dynamic_mask) == (pattern & dynamic_mask));
endmodule
