module CascadeOR(
    input [2:0] in,
    output out
);
    wire t1, t2;
    or(t1, in[0], in[1]);
    or(t2, t1, in[2]);
    assign out = t2;
endmodule
