module or_gate_4input_32bit (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [31:0] c,
    input wire [31:0] d,
    output wire [31:0] y
);
    assign y = a | b | c | d;
endmodule
