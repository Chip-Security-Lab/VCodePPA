module ConditionalOR(
    input cond,
    input [7:0] mask, data,
    output [7:0] result
);
    assign result = cond ? (data | mask) : data;
endmodule
