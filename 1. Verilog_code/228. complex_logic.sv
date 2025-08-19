module complex_logic (
    input [3:0] a, b, c,
    output [3:0] res1,
    output [3:0] res2
);
    assign res1 = (a | b) & c;
    assign res2 = (a ^ b) + c;
endmodule
