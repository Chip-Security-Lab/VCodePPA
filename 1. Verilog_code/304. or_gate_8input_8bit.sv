module or_gate_8input_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    input wire [7:0] e,
    input wire [7:0] f,
    input wire [7:0] g,
    input wire [7:0] h,
    output wire [7:0] y
);
    assign y = a | b | c | d | e | f | g | h;
endmodule
