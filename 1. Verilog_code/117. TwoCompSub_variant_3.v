// Negation submodule
module Negate(
    input signed [7:0] in,
    output signed [7:0] out
);
    assign out = -in;
endmodule

// Addition submodule
module Add(
    input signed [7:0] a, b,
    output signed [7:0] sum
);
    assign sum = a + b;
endmodule

// Top-level module
module TwoCompSub(
    input signed [7:0] a, b,
    output signed [7:0] res
);
    wire signed [7:0] neg_b;
    
    // Instantiate negation submodule
    Negate negate_inst(
        .in(b),
        .out(neg_b)
    );
    
    // Instantiate addition submodule
    Add add_inst(
        .a(a),
        .b(neg_b),
        .sum(res)
    );
endmodule