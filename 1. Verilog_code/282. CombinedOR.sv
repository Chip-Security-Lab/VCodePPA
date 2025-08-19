module CombinedOR(
    input [1:0] sel,
    input [3:0] a, b, c, d,
    output [3:0] res
);
    assign res = (sel[1] ? (a | b) : 4'b0) | 
                (sel[0] ? (c | d) : 4'b0);
endmodule
