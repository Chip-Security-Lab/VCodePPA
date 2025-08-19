module MedianFilter #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b, c,
    output [WIDTH-1:0] med
);
    wire [WIDTH-1:0] max_ab = (a > b) ? a : b;
    wire [WIDTH-1:0] min_ab = (a < b) ? a : b;
    assign med = (c > max_ab) ? max_ab : ((c < min_ab) ? min_ab : c);
endmodule