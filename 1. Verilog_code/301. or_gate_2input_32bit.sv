module or_gate_2input_32bit (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] y
);
    assign y = a | b;
endmodule
