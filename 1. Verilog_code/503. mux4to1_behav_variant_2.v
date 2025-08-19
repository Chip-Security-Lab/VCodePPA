module karatsuba_multiplier(
    input [3:0] a,
    input [3:0] b,
    output [7:0] result
);

    wire [1:0] a_high = a[3:2];
    wire [1:0] a_low = a[1:0];
    wire [1:0] b_high = b[3:2];
    wire [1:0] b_low = b[1:0];

    wire [3:0] z0, z1, z2;
    wire [3:0] a_sum = a_high + a_low;
    wire [3:0] b_sum = b_high + b_low;

    karatsuba_mult_2bit mult0(.a(a_low), .b(b_low), .result(z0));
    karatsuba_mult_2bit mult1(.a(a_high), .b(b_high), .result(z1));
    karatsuba_mult_2bit mult2(.a(a_sum), .b(b_sum), .result(z2));

    wire [7:0] z0_ext = {4'b0, z0};
    wire [7:0] z1_ext = {z1, 4'b0};
    wire [7:0] z2_ext = {2'b0, z2, 2'b0};

    assign result = z1_ext + (z2_ext - z0_ext - z1_ext) + z0_ext;

endmodule

module karatsuba_mult_2bit(
    input [1:0] a,
    input [1:0] b,
    output [3:0] result
);

    wire [0:0] a_high = a[1];
    wire [0:0] a_low = a[0];
    wire [0:0] b_high = b[1];
    wire [0:0] b_low = b[0];

    wire [1:0] z0, z1, z2;
    wire [1:0] a_sum = a_high + a_low;
    wire [1:0] b_sum = b_high + b_low;

    assign z0 = a_low & b_low;
    assign z1 = a_high & b_high;
    assign z2 = a_sum & b_sum;

    wire [3:0] z0_ext = {2'b0, z0};
    wire [3:0] z1_ext = {z1, 2'b0};
    wire [3:0] z2_ext = {1'b0, z2, 1'b0};

    assign result = z1_ext + (z2_ext - z0_ext - z1_ext) + z0_ext;

endmodule