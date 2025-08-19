module mult_direct #(parameter N=8) (
    input [N-1:0] a, b,
    output [2*N-1:0] prod
);
    assign prod = a * b;
endmodule
