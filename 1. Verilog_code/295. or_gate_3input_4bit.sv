module or_gate_3input_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    output wire [3:0] y
);
    assign y = a | b | c;
endmodule
