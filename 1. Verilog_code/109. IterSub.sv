module IterSub(
    input [7:0] a, b,
    output [7:0] res
);
    assign res = a % b;
endmodule