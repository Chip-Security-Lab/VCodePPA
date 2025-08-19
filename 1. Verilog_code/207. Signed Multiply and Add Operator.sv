module signed_multiply_add (
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output signed [15:0] result
);
    assign result = (a * b) + c;  // 乘法与加法
endmodule

