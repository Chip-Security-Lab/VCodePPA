module arithmetic_unit #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum,
    output [WIDTH-1:0] diff
);

    // Internal signals
    wire [WIDTH-1:0] b_neg;
    
    // Instantiate submodules
    twos_complement #(WIDTH) tc_inst (
        .in(b),
        .out(b_neg)
    );
    
    adder_8bit #(WIDTH) adder_inst (
        .a(a),
        .b(b),
        .sum(sum)
    );
    
    adder_8bit #(WIDTH) subtractor_inst (
        .a(a),
        .b(b_neg),
        .sum(diff)
    );
endmodule

module twos_complement #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    assign out = ~in + 1'b1;
endmodule

module adder_8bit #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    assign sum = a + b;
endmodule