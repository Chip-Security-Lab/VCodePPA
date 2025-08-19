module mag_compare(
    input a, b,
    output eq, gt
);
    wire xn;
    xor(xn, a, b);
    not(eq, xn);
    and(gt, a, ~b);
endmodule