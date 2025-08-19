//SystemVerilog
module generic_mult #(parameter WIDTH=8) (
    input [WIDTH-1:0] operand1,
    input [WIDTH-1:0] operand2,
    output [2*WIDTH-1:0] product
);

    wire [WIDTH/2-1:0] a_high = operand1[WIDTH-1:WIDTH/2];
    wire [WIDTH/2-1:0] a_low = operand1[WIDTH/2-1:0];
    wire [WIDTH/2-1:0] b_high = operand2[WIDTH-1:WIDTH/2];
    wire [WIDTH/2-1:0] b_low = operand2[WIDTH/2-1:0];

    wire [WIDTH-1:0] z0, z1, z2;
    wire [WIDTH-1:0] a_sum = a_high + a_low;
    wire [WIDTH-1:0] b_sum = b_high + b_low;

    // Optimized multiplication using Booth encoding
    booth_mult #(.WIDTH(WIDTH/2)) mult_z0 (
        .operand1(a_low),
        .operand2(b_low),
        .product(z0)
    );

    booth_mult #(.WIDTH(WIDTH/2)) mult_z1 (
        .operand1(a_high),
        .operand2(b_high),
        .product(z1)
    );

    booth_mult #(.WIDTH(WIDTH/2)) mult_z2 (
        .operand1(a_sum),
        .operand2(b_sum),
        .product(z2)
    );

    // Optimized addition chain
    wire [2*WIDTH-1:0] z1_shifted = z1 << WIDTH;
    wire [2*WIDTH-1:0] z2_minus_z1 = z2 - z1;
    wire [2*WIDTH-1:0] z2_minus_z1_minus_z0 = (z2_minus_z1 - z0) << (WIDTH/2);

    // Wallace tree adder for final sum
    wallace_adder #(.WIDTH(2*WIDTH)) final_adder (
        .a(z1_shifted),
        .b(z2_minus_z1_minus_z0),
        .c(z0),
        .sum(product)
    );

endmodule

module booth_mult #(parameter WIDTH=4) (
    input [WIDTH-1:0] operand1,
    input [WIDTH-1:0] operand2,
    output [2*WIDTH-1:0] product
);

    generate
        if (WIDTH <= 4) begin
            // Direct multiplication for small operands
            assign product = operand1 * operand2;
        end else begin
            wire [WIDTH/2-1:0] a_high = operand1[WIDTH-1:WIDTH/2];
            wire [WIDTH/2-1:0] a_low = operand1[WIDTH/2-1:0];
            wire [WIDTH/2-1:0] b_high = operand2[WIDTH-1:WIDTH/2];
            wire [WIDTH/2-1:0] b_low = operand2[WIDTH/2-1:0];

            wire [WIDTH-1:0] z0, z1, z2;
            wire [WIDTH-1:0] a_sum = a_high + a_low;
            wire [WIDTH-1:0] b_sum = b_high + b_low;

            booth_mult #(.WIDTH(WIDTH/2)) mult_z0 (
                .operand1(a_low),
                .operand2(b_low),
                .product(z0)
            );

            booth_mult #(.WIDTH(WIDTH/2)) mult_z1 (
                .operand1(a_high),
                .operand2(b_high),
                .product(z1)
            );

            booth_mult #(.WIDTH(WIDTH/2)) mult_z2 (
                .operand1(a_sum),
                .operand2(b_sum),
                .product(z2)
            );

            wire [2*WIDTH-1:0] z1_shifted = z1 << WIDTH;
            wire [2*WIDTH-1:0] z2_minus_z1 = z2 - z1;
            wire [2*WIDTH-1:0] z2_minus_z1_minus_z0 = (z2_minus_z1 - z0) << (WIDTH/2);

            wallace_adder #(.WIDTH(2*WIDTH)) final_adder (
                .a(z1_shifted),
                .b(z2_minus_z1_minus_z0),
                .c(z0),
                .sum(product)
            );
        end
    endgenerate

endmodule

module wallace_adder #(parameter WIDTH=16) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [WIDTH-1:0] c,
    output [WIDTH-1:0] sum
);

    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum1, sum2;

    // First level of addition
    assign {carry[0], sum1} = a + b;
    
    // Second level of addition
    assign {carry[1], sum} = sum1 + c;

    // Final carry propagation
    assign carry[WIDTH:2] = carry[WIDTH-1:1];

endmodule