module or_gate_3input_1bit (
    input wire a,
    input wire b,
    input wire c,
    output wire y
);
    assign y = a | b | c;
endmodule
