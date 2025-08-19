//SystemVerilog
module CondNor(
    input  [7:0] a,
    input  [7:0] b,
    output reg [15:0] y
);
    wire [15:0] karatsuba_result;

    Karatsuba8x8 karatsuba_mul_inst (
        .a(a),
        .b(b),
        .prod(karatsuba_result)
    );

    always @(*) begin
        if (|a || |b) begin
            y = 16'b0;
        end else begin
            y = karatsuba_result;
        end
    end
endmodule

module Karatsuba8x8(
    input  [7:0]  a,
    input  [7:0]  b,
    output [15:0] prod
);
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low  = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low  = b[3:0];

    wire [7:0] z0;
    wire [7:0] z2;
    wire [7:0] z1;
    wire [4:0] a_sum = a_high + a_low;
    wire [4:0] b_sum = b_high + b_low;
    wire [7:0] z1_temp;

    Karatsuba4x4 karatsuba_low (
        .a(a_low),
        .b(b_low),
        .prod(z0)
    );

    Karatsuba4x4 karatsuba_high (
        .a(a_high),
        .b(b_high),
        .prod(z2)
    );

    Karatsuba4x4 karatsuba_mid (
        .a(a_sum[3:0]),
        .b(b_sum[3:0]),
        .prod(z1_temp)
    );

    assign z1 = z1_temp - z0 - z2;
    assign prod = {z2, 8'b0} + {z1, 4'b0} + z0;
endmodule

module Karatsuba4x4(
    input  [3:0] a,
    input  [3:0] b,
    output [7:0] prod
);
    wire [1:0] a_high = a[3:2];
    wire [1:0] a_low  = a[1:0];
    wire [1:0] b_high = b[3:2];
    wire [1:0] b_low  = b[1:0];

    wire [3:0] z0;
    wire [3:0] z2;
    wire [3:0] z1;
    wire [2:0] a_sum = a_high + a_low;
    wire [2:0] b_sum = b_high + b_low;
    wire [3:0] z1_temp;

    Karatsuba2x2 karatsuba_low (
        .a(a_low),
        .b(b_low),
        .prod(z0)
    );

    Karatsuba2x2 karatsuba_high (
        .a(a_high),
        .b(b_high),
        .prod(z2)
    );

    Karatsuba2x2 karatsuba_mid (
        .a(a_sum[1:0]),
        .b(b_sum[1:0]),
        .prod(z1_temp)
    );

    assign z1 = z1_temp - z0 - z2;
    assign prod = {z2, 4'b0} + {z1, 2'b0} + z0;
endmodule

module Karatsuba2x2(
    input  [1:0] a,
    input  [1:0] b,
    output [3:0] prod
);
    wire [3:0] z0 = a[0] * b[0];
    wire [3:0] z2 = a[1] * b[1];
    wire [1:0] a_sum = a[1] + a[0];
    wire [1:0] b_sum = b[1] + b[0];
    wire [3:0] z1_temp = a_sum * b_sum;
    wire [3:0] z1 = z1_temp - z0 - z2;
    assign prod = {z2,2'b00} + {z1,1'b0} + z0;
endmodule