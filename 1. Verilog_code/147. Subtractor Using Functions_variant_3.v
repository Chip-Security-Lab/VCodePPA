module complement_generator (
    input wire [7:0] b,
    output wire [7:0] b_comp
);
    assign b_comp = ~b + 1'b1;
endmodule

module adder_core (
    input wire [7:0] a,
    input wire [7:0] b_comp,
    output wire carry_out,
    output wire [7:0] sum_result
);
    assign {carry_out, sum_result} = a + b_comp;
endmodule

module subtractor_function (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] res
);

    wire [7:0] b_comp;
    wire [7:0] sum_result;
    wire carry_out;

    complement_generator comp_gen (
        .b(b),
        .b_comp(b_comp)
    );

    adder_core adder (
        .a(a),
        .b_comp(b_comp),
        .carry_out(carry_out),
        .sum_result(sum_result)
    );

    assign res = sum_result;

endmodule