module or_gate_4input_delayed (
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    output wire y
);
    assign #5 y = a | b | c | d;  // 延迟5单位时间
endmodule
