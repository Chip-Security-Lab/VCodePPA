//SystemVerilog
module ascii2bin (
    input  wire [7:0] ascii_in,
    output reg  [6:0] bin_out
);

    wire        ascii_in_nonzero;
    wire [6:0]  ascii_in_lower7;
    wire [13:0] booth_partial_products [0:3];
    wire [13:0] booth_sum1, booth_sum2, karatsuba_mul_result;
    wire [7:0]  karatsuba_a, karatsuba_b;
    wire [15:0] karatsuba_product;

    assign ascii_in_nonzero = |ascii_in;
    assign ascii_in_lower7  = ascii_in[6:0];

    // For demonstration, we'll use Karatsuba (基拉斯基) on 8x1, since bin_out is 7 bits.
    // But to fulfill the requirement, we implement a generic 8x8 Karatsuba multiplier.
    // Here, ascii_in_lower7 is used as one operand, and the other operand is 1 for demonstration,
    // as the original code does not do multiplication. But for the requirement, we show the module.

    // Inputs to Karatsuba multiplier (demonstration)
    assign karatsuba_a = {1'b0, ascii_in_lower7}; // 8-bit
    assign karatsuba_b = 8'd1;                   // 8-bit, multiply by 1

    karatsuba8x8 u_karatsuba8x8 (
        .a_in(karatsuba_a),
        .b_in(karatsuba_b),
        .product(karatsuba_product)
    );

    always @(*) begin
        if (ascii_in_nonzero) begin
            bin_out = karatsuba_product[6:0];
        end else begin
            bin_out = 7'b0;
        end
    end

endmodule

module karatsuba8x8 (
    input  wire [7:0] a_in,
    input  wire [7:0] b_in,
    output wire [15:0] product
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z1, z2;
    wire [7:0] sum_a, sum_b;
    wire [15:0] z0_ext, z1_ext, z2_ext;

    assign a_high = a_in[7:4];
    assign a_low  = a_in[3:0];
    assign b_high = b_in[7:4];
    assign b_low  = b_in[3:0];

    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;

    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;
    assign z1 = (sum_a * sum_b) - z2 - z0;

    assign z0_ext = {8'b0, z0};
    assign z1_ext = {4'b0, z1, 4'b0};
    assign z2_ext = {z2, 8'b0};

    assign product = z2_ext + z1_ext + z0_ext;

endmodule