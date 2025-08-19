//SystemVerilog
module signed_mult (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [15:0] p
);

    wire signed [7:0] a_high, a_low;
    wire signed [7:0] b_high, b_low;
    wire signed [7:0] z0, z1, z2;
    wire signed [7:0] sum_a, sum_b;

    input_splitter split_a (
        .in(a),
        .high(a_high),
        .low(a_low)
    );

    input_splitter split_b (
        .in(b),
        .high(b_high),
        .low(b_low)
    );

    product_calculator products (
        .a_high(a_high),
        .a_low(a_low),
        .b_high(b_high),
        .b_low(b_low),
        .z0(z0),
        .z1(z1),
        .z2(z2)
    );

    result_assembler assembler (
        .z0(z0),
        .z1(z1),
        .z2(z2),
        .p(p)
    );

endmodule

module input_splitter (
    input signed [7:0] in,
    output signed [7:0] high,
    output signed [7:0] low
);
    assign high = in[7:4];
    assign low = in[3:0];
endmodule

module product_calculator (
    input signed [7:0] a_high,
    input signed [7:0] a_low,
    input signed [7:0] b_high,
    input signed [7:0] b_low,
    output signed [7:0] z0,
    output signed [7:0] z1,
    output signed [7:0] z2
);
    wire signed [7:0] sum_a, sum_b;
    
    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;
    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;
    assign z1 = sum_a * sum_b - z0 - z2;
endmodule

module result_assembler (
    input signed [7:0] z0,
    input signed [7:0] z1,
    input signed [7:0] z2,
    output signed [15:0] p
);
    wire signed [15:0] z2_shifted, z1_shifted;
    
    // Barrel shifter implementation
    assign z2_shifted = {z2, 8'b0};
    assign z1_shifted = {{8{z1[7]}}, z1, 4'b0};
    
    assign p = z2_shifted + z1_shifted + z0;
endmodule