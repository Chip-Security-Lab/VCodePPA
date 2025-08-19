module complement_generator_8bit (
    input [7:0] data_in,
    output [7:0] complement_out
);
    assign complement_out = ~data_in + 1'b1;
endmodule

module adder_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output carry_out
);
    assign {carry_out, sum} = a + b;
endmodule

module unsigned_subtractor_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff
);
    wire [7:0] b_comp;
    wire carry_out;

    complement_generator_8bit comp_gen (
        .data_in(b),
        .complement_out(b_comp)
    );

    adder_8bit adder (
        .a(a),
        .b(b_comp),
        .sum(diff),
        .carry_out(carry_out)
    );
endmodule