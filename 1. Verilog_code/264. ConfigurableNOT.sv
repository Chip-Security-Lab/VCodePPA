module ConfigurableNOT(
    input pol,       // 极性控制
    input [7:0] in,
    output [7:0] out
);
    assign out = pol ? ~in : in;  // 极性选择
endmodule
