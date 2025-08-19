module complement_generator (
    input wire [3:0] b,
    output wire [3:0] b_comp
);
    assign b_comp = ~b + 1'b1;
endmodule

module adder_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] sum,
    output wire cout
);
    assign {cout, sum} = a + b;
endmodule

module subtractor_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output reg [3:0] res
);

    wire [3:0] b_comp;
    wire [3:0] sum;
    wire cout;

    complement_generator comp_gen (
        .b(b),
        .b_comp(b_comp)
    );

    adder_4bit adder (
        .a(a),
        .b(b_comp),
        .sum(sum),
        .cout(cout)
    );

    always @(*) begin
        res = sum;
    end

endmodule