module SignedDiv(
    input signed [7:0] num, den,
    output signed [7:0] q
);
    assign q = (den != 0) ? num / den : 8'h80;
endmodule
