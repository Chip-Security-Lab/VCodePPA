module DivRem(
    input [7:0] num, den,
    output [7:0] q, r
);
    // 添加除零保护
    assign q = (den != 0) ? num / den : 8'hFF;
    assign r = (den != 0) ? num % den : num;
endmodule