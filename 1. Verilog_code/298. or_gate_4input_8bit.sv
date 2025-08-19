module or_gate_4input_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    output wire [7:0] y
);
    assign y = a | b | c | d;
endmodule
