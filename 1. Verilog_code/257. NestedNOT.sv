module NestedNOT(
    input sig,
    output out
);
    wire intermediate;
    not U1(intermediate, sig);
    not U2(out, intermediate);  // 双非门级联
endmodule
