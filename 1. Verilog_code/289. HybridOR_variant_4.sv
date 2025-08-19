//SystemVerilog
module karatsuba_mult_8bit(
    input [7:0] a,
    input [7:0] b,
    output [15:0] p
);

    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z2, z0;
    wire [8:0] a_plus_b_low, a_plus_b_high;
    wire [9:0] z1_intermediate;
    wire [15:0] z1_shifted;
    wire [15:0] z2_shifted;
    wire [9:0] z1_intermediate_mult;

    assign a_high = a[7:4];
    assign a_low  = a[3:0];
    assign b_high = b[7:4];
    assign b_low  = b[3:0];

    karatsuba_mult_4bit mult_z2 (
        .a(a_high),
        .b(b_high),
        .p(z2)
    );

    karatsuba_mult_4bit mult_z0 (
        .a(a_low),
        .b(b_low),
        .p(z0)
    );

    assign a_plus_b_low = {1'b0, a_low} + {1'b0, b_low};
    assign a_plus_b_high = {1'b0, a_high} + {1'b0, b_high};

    karatsuba_mult_5bit mult_z1 (
        .a(a_plus_b_high),
        .b(a_plus_b_low),
        .p(z1_intermediate_mult)
    );

    assign z1_intermediate = z1_intermediate_mult - z2 - z0;

    assign z2_shifted = z2 << 8;
    assign z1_shifted = z1_intermediate << 4;

    assign p = z2_shifted + z1_shifted + z0;

endmodule

module karatsuba_mult_5bit(
    input [4:0] a,
    input [4:0] b,
    output [9:0] p
);
    wire [2:0] a_high, a_low, b_high, b_low;
    wire [5:0] z2, z0;
    wire [5:0] a_plus_b_low, a_plus_b_high;
    wire [6:0] z1_intermediate;
    wire [9:0] z1_shifted;
    wire [9:0] z2_shifted;
    wire [6:0] z1_intermediate_mult;


    assign a_high = a[4:2];
    assign a_low  = a[1:0]; // Note: a_low is 2 bits
    assign b_high = b[4:2];
    assign b_low  = b[1:0]; // Note: b_low is 2 bits

    karatsuba_mult_3bit mult_z2 (
        .a(a_high),
        .b(b_high),
        .p(z2)
    );

    karatsuba_mult_2bit mult_z0 (
        .a(a_low),
        .b(b_low),
        .p(z0)
    );

    assign a_plus_b_low = {3'b0, a_low} + {3'b0, b_low};
    assign a_plus_b_high = {2'b0, a_high} + {2'b0, b_high};

    karatsuba_mult_3bit mult_z1 ( // Use 3-bit multiplier for intermediate (3x3)
        .a(a_plus_b_high),
        .b(a_plus_b_low),
        .p(z1_intermediate_mult)
    );

    assign z1_intermediate = z1_intermediate_mult - z2 - z0;

    assign z2_shifted = z2 << 4;
    assign z1_shifted = z1_intermediate << 2;

    assign p = z2_shifted + z1_shifted + z0;

endmodule

module karatsuba_mult_4bit(
    input [3:0] a,
    input [3:0] b,
    output [7:0] p
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z2, z0;
    wire [4:0] a_plus_b_low, a_plus_b_high;
    wire [4:0] z1_intermediate;
    wire [7:0] z1_shifted;
    wire [7:0] z2_shifted;
    wire [4:0] z1_intermediate_mult;


    assign a_high = a[3:2];
    assign a_low  = a[1:0];
    assign b_high = b[3:2];
    assign b_low  = b[1:0];

    karatsuba_mult_2bit mult_z2 (
        .a(a_high),
        .b(b_high),
        .p(z2)
    );

    karatsuba_mult_2bit mult_z0 (
        .a(a_low),
        .b(b_low),
        .p(z0)
    );

    assign a_plus_b_low = {2'b0, a_low} + {2'b0, b_low};
    assign a_plus_b_high = {2'b0, a_high} + {2'b0, b_high};

    karatsuba_mult_3bit mult_z1 ( // Use 3-bit multiplier for intermediate (3x3)
        .a(a_plus_b_high),
        .b(a_plus_b_low),
        .p(z1_intermediate_mult)
    );

    assign z1_intermediate = z1_intermediate_mult - z2 - z0;

    assign z2_shifted = z2 << 4;
    assign z1_shifted = z1_intermediate << 2;

    assign p = z2_shifted + z1_shifted + z0;

endmodule

module karatsuba_mult_3bit(
    input [2:0] a,
    input [2:0] b,
    output [5:0] p
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z2, z0;
    wire [3:0] a_plus_b_low, a_plus_b_high;
    wire [3:0] z1_intermediate;
    wire [5:0] z1_shifted;
    wire [5:0] z2_shifted;
    wire [3:0] z1_intermediate_mult;


    assign a_high = a[2]; // 1 bit
    assign a_low  = a[1:0]; // 2 bits
    assign b_high = b[2]; // 1 bit
    assign b_low  = b[1:0]; // 2 bits

    karatsuba_mult_1bit mult_z2 (
        .a(a_high),
        .b(b_high),
        .p(z2)
    );

    karatsuba_mult_2bit mult_z0 (
        .a(a_low),
        .b(b_low),
        .p(z0)
    );

    assign a_plus_b_low = {1'b0, a_low} + {1'b0, b_low};
    assign a_plus_b_high = {2'b0, a_high} + {2'b0, b_high};

    karatsuba_mult_2bit mult_z1 ( // Use 2-bit multiplier for intermediate (3x3)
        .a(a_plus_b_high),
        .b(a_plus_b_low),
        .p(z1_intermediate_mult)
    );

    assign z1_intermediate = z1_intermediate_mult - z2 - z0;

    assign z2_shifted = z2 << 4; // Shift by 2*2 = 4
    assign z1_shifted = z1_intermediate << 2; // Shift by 2

    assign p = z2_shifted + z1_shifted + z0;

endmodule

module karatsuba_mult_2bit(
    input [1:0] a,
    input [1:0] b,
    output [3:0] p
);
    assign p = a * b; // Base case: standard multiplication
endmodule

module karatsuba_mult_1bit(
    input [0:0] a,
    input [0:0] b,
    output [1:0] p
);
    assign p = a * b; // Base case: standard multiplication
endmodule


module HybridOR(
    input [1:0] sel,
    input [7:0] data,
    output [7:0] result
);
    wire [15:0] shift_amount_karatsuba;
    wire [7:0] shift_amount_data;

    karatsuba_mult_8bit shift_mult (
        .a({6'b0, sel, 2'b0}), // Input 'a' for multiplication
        .b({6'b0, 2'd2}), // Input 'b' for multiplication (constant 2)
        .p(shift_amount_karatsuba)
    );

    assign shift_amount_data = shift_amount_karatsuba[7:0]; // Use lower 8 bits for shifting

    assign result = data | (8'hFF << shift_amount_data);
endmodule