module incrementers (
    input [5:0] base,
    output [5:0] double,
    output [5:0] triple
);
    assign double = base << 1;
    assign triple = base + (base << 1);
endmodule
