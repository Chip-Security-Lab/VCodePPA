module or_gate_3input_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    output wire [7:0] y
);
    assign y = a | b | c;
endmodule
