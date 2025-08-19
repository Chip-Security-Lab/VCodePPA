//SystemVerilog
module thermal_noise_rng (
    input wire clock,
    input wire reset,
    output reg [15:0] random_out
);
    reg [31:0] noise_gen_x;
    reg [31:0] noise_gen_y;

    wire [31:0] lcg_x_mul_result;
    wire [31:0] lcg_y_mul_result;
    wire [7:0] mul_x, mul_y;
    wire [15:0] box_muller_mul_result;

    // Karatsuba Multiplier for LCG X
    karatsuba_32x32 lcg_x_karatsuba (
        .a(noise_gen_x),
        .b(32'd1103515245),
        .p(lcg_x_mul_result)
    );

    // Karatsuba Multiplier for LCG Y
    karatsuba_32x32 lcg_y_karatsuba (
        .a(noise_gen_y),
        .b(32'd214013),
        .p(lcg_y_mul_result)
    );

    assign mul_x = noise_gen_x[31:24];
    assign mul_y = noise_gen_y[31:24];

    // Karatsuba Multiplier for Box-Muller output (8x8)
    karatsuba_8x8 box_muller_karatsuba (
        .a(mul_x),
        .b(mul_y),
        .p(box_muller_mul_result)
    );

    wire [31:0] lcg_x_next;
    wire [31:0] lcg_y_next;

    // 32-bit Carry Select Adder for noise_gen_x update
    carry_select_adder_32 adder_x (
        .a(lcg_x_mul_result),
        .b(32'd12345),
        .sum(lcg_x_next)
    );

    // 32-bit Carry Select Adder for noise_gen_y update
    carry_select_adder_32 adder_y (
        .a(lcg_y_mul_result),
        .b(32'd2531011),
        .sum(lcg_y_next)
    );

    always @(posedge clock) begin
        if (reset) begin
            noise_gen_x <= 32'h12345678;
            noise_gen_y <= 32'h87654321;
            random_out <= 16'h0;
        end else begin
            noise_gen_x <= lcg_x_next;
            noise_gen_y <= lcg_y_next;
            random_out <= box_muller_mul_result;
        end
    end
endmodule

// 32-bit Carry Select Adder (CSA)
module carry_select_adder_32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] sum
);
    wire [7:0] sum0_0, sum0_1, sum1_0, sum1_1, sum2_0, sum2_1, sum3_0, sum3_1;
    wire c0, c1_0, c1_1, c2_0, c2_1, c3_0, c3_1;
    wire [7:0] a0 = a[7:0],   b0 = b[7:0];
    wire [7:0] a1 = a[15:8],  b1 = b[15:8];
    wire [7:0] a2 = a[23:16], b2 = b[23:16];
    wire [7:0] a3 = a[31:24], b3 = b[31:24];

    // First block: ripple carry adder
    ripple_carry_adder_8 rca0 (
        .a(a0),
        .b(b0),
        .cin(1'b0),
        .sum(sum0_0),
        .cout(c0)
    );
    // Second block: CSA
    ripple_carry_adder_8 rca1_0 (
        .a(a1),
        .b(b1),
        .cin(1'b0),
        .sum(sum1_0),
        .cout(c1_0)
    );
    ripple_carry_adder_8 rca1_1 (
        .a(a1),
        .b(b1),
        .cin(1'b1),
        .sum(sum1_1),
        .cout(c1_1)
    );
    // Third block: CSA
    ripple_carry_adder_8 rca2_0 (
        .a(a2),
        .b(b2),
        .cin(1'b0),
        .sum(sum2_0),
        .cout(c2_0)
    );
    ripple_carry_adder_8 rca2_1 (
        .a(a2),
        .b(b2),
        .cin(1'b1),
        .sum(sum2_1),
        .cout(c2_1)
    );
    // Fourth block: CSA
    ripple_carry_adder_8 rca3_0 (
        .a(a3),
        .b(b3),
        .cin(1'b0),
        .sum(sum3_0),
        .cout(c3_0)
    );
    ripple_carry_adder_8 rca3_1 (
        .a(a3),
        .b(b3),
        .cin(1'b1),
        .sum(sum3_1),
        .cout(c3_1)
    );

    // Selects for each block
    wire select1 = c0;
    wire select2 = select1 ? c1_1 : c1_0;
    wire select3 = select2 ? c2_1 : c2_0;

    assign sum[7:0]   = sum0_0;
    assign sum[15:8]  = select1 ? sum1_1 : sum1_0;
    assign sum[23:16] = select2 ? sum2_1 : sum2_0;
    assign sum[31:24] = select3 ? sum3_1 : sum3_0;
endmodule

// 8-bit Ripple Carry Adder
module ripple_carry_adder_8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire cin,
    output wire [7:0] sum,
    output wire cout
);
    wire [7:0] carry;
    assign {carry[0], sum[0]} = a[0] + b[0] + cin;
    assign {carry[1], sum[1]} = a[1] + b[1] + carry[0];
    assign {carry[2], sum[2]} = a[2] + b[2] + carry[1];
    assign {carry[3], sum[3]} = a[3] + b[3] + carry[2];
    assign {carry[4], sum[4]} = a[4] + b[4] + carry[3];
    assign {carry[5], sum[5]} = a[5] + b[5] + carry[4];
    assign {carry[6], sum[6]} = a[6] + b[6] + carry[5];
    assign {cout,    sum[7]} = a[7] + b[7] + carry[6];
endmodule

// 32x32 Karatsuba Multiplier
module karatsuba_32x32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] p
);
    wire [15:0] a_high = a[31:16];
    wire [15:0] a_low  = a[15:0];
    wire [15:0] b_high = b[31:16];
    wire [15:0] b_low  = b[15:0];

    wire [31:0] z0;
    wire [31:0] z2;
    wire [31:0] z1;
    wire [31:0] a_sum, b_sum;
    wire [31:0] z1_intermediate;

    karatsuba_16x16 mul_z0 (.a(a_low),  .b(b_low),  .p(z0));
    karatsuba_16x16 mul_z2 (.a(a_high), .b(b_high), .p(z2));

    assign a_sum = a_low + a_high;
    assign b_sum = b_low + b_high;

    karatsuba_16x16 mul_z1 (.a(a_sum), .b(b_sum), .p(z1_intermediate));

    assign z1 = z1_intermediate - z2 - z0;

    assign p = (z2 << 32) + (z1 << 16) + z0;
endmodule

// 16x16 Karatsuba Multiplier
module karatsuba_16x16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] p
);
    wire [7:0] a_high = a[15:8];
    wire [7:0] a_low  = a[7:0];
    wire [7:0] b_high = b[15:8];
    wire [7:0] b_low  = b[7:0];

    wire [15:0] z0;
    wire [15:0] z2;
    wire [15:0] z1;
    wire [8:0] a_sum, b_sum;
    wire [15:0] z1_intermediate;

    karatsuba_8x8 mul_z0 (.a(a_low),  .b(b_low),  .p(z0));
    karatsuba_8x8 mul_z2 (.a(a_high), .b(b_high), .p(z2));

    assign a_sum = a_low + a_high;
    assign b_sum = b_low + b_high;

    karatsuba_8x8 mul_z1 (.a(a_sum[7:0]), .b(b_sum[7:0]), .p(z1_intermediate));

    assign z1 = z1_intermediate - z2 - z0;

    assign p = (z2 << 16) + (z1 << 8) + z0;
endmodule

// 8x8 Karatsuba Multiplier
module karatsuba_8x8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [15:0] p
);
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low  = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low  = b[3:0];

    wire [7:0] z0;
    wire [7:0] z2;
    wire [7:0] z1;
    wire [4:0] a_sum, b_sum;
    wire [7:0] z1_intermediate;

    assign a_sum = a_low + a_high;
    assign b_sum = b_low + b_high;

    karatsuba_4x4 mul_z0 (.a(a_low),  .b(b_low),  .p(z0));
    karatsuba_4x4 mul_z2 (.a(a_high), .b(b_high), .p(z2));
    karatsuba_4x4 mul_z1 (.a(a_sum[3:0]), .b(b_sum[3:0]), .p(z1_intermediate));

    assign z1 = z1_intermediate - z2 - z0;

    assign p = (z2 << 8) + (z1 << 4) + z0;
endmodule

// 4x4 Karatsuba Multiplier
module karatsuba_4x4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] p
);
    wire [1:0] a_high = a[3:2];
    wire [1:0] a_low  = a[1:0];
    wire [1:0] b_high = b[3:2];
    wire [1:0] b_low  = b[1:0];

    wire [3:0] z0;
    wire [3:0] z2;
    wire [3:0] z1;
    wire [2:0] a_sum, b_sum;
    wire [3:0] z1_intermediate;

    assign a_sum = a_low + a_high;
    assign b_sum = b_low + b_high;

    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;
    assign z1_intermediate = (a_sum[1:0]) * (b_sum[1:0]);
    assign z1 = z1_intermediate - z2 - z0;

    assign p = (z2 << 4) + (z1 << 2) + z0;
endmodule