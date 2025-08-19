module or_gate_3input_16bit (
    input wire [15:0] a,
    input wire [15:0] b,
    input wire [15:0] c,
    output wire [15:0] y
);
    assign y = a | b | c;
endmodule
