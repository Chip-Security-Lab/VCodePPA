module mult_unrolled (
    input [3:0] x, y,
    output [7:0] result
);
    wire [7:0] p0 = y[0] ? {4'b0, x} : 8'b0;
    wire [7:0] p1 = y[1] ? {3'b0, x, 1'b0} : 8'b0;
    wire [7:0] p2 = y[2] ? {2'b0, x, 2'b0} : 8'b0;
    wire [7:0] p3 = y[3] ? {1'b0, x, 3'b0} : 8'b0;
    assign result = p0 + p1 + p2 + p3;
endmodule
