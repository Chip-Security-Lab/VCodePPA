//SystemVerilog

module demux_1to4_case (
    input wire din,                  // Data input
    input wire [1:0] select,         // 2-bit selection control
    output reg [3:0] dout            // 4-bit output bus
);
    wire [3:0] karatsuba_result;

    karatsuba_4bit_multiplier u_karatsuba_mult (
        .a(4'b0001 << select),
        .b({3'b000, din}),
        .product(karatsuba_result)
    );

    always @(*) begin
        dout = karatsuba_result;
    end
endmodule

module karatsuba_4bit_multiplier (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] product
);
    wire [6:0] full_product;

    karatsuba_4bit_core u_karatsuba_core (
        .a(a),
        .b(b),
        .product(full_product)
    );

    assign product = full_product[3:0];
endmodule

module karatsuba_4bit_core (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [6:0] product
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z0, z2;
    wire [3:0] z1_temp;
    wire [2:0] sum_a, sum_b;
    wire [3:0] z1;
    wire [6:0] product_internal;

    assign a_high = a[3:2];
    assign a_low  = a[1:0];
    assign b_high = b[3:2];
    assign b_low  = b[1:0];

    karatsuba_2bit_multiplier u_z0 (
        .a(a_low),
        .b(b_low),
        .product(z0)
    );

    karatsuba_2bit_multiplier u_z2 (
        .a(a_high),
        .b(b_high),
        .product(z2)
    );

    assign sum_a = {1'b0, a_low} + {1'b0, a_high};
    assign sum_b = {1'b0, b_low} + {1'b0, b_high};

    karatsuba_2bit_multiplier u_z1 (
        .a(sum_a[1:0]),
        .b(sum_b[1:0]),
        .product(z1_temp)
    );

    assign z1 = z1_temp - z0 - z2;

    assign product_internal = {z2, 4'b0} + {z1, 2'b00} + {3'b000, z0};
    assign product = product_internal[6:0];
endmodule

module karatsuba_2bit_multiplier (
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [3:0] product
);
    wire [3:0] partial_product;
    reg [3:0] product_next;

    // Optimized comparison and multiplication logic using range checking
    assign partial_product = (a == 2'b00 || b == 2'b00) ? 4'b0000 :
                            (a == 2'b01) ? {2'b00, b} :
                            (b == 2'b01) ? {2'b00, a} :
                            (a == 2'b10 && b == 2'b10) ? 4'b0100 :
                            (a == 2'b10 && b == 2'b11) ? 4'b0110 :
                            (a == 2'b11 && b == 2'b10) ? 4'b0110 :
                            (a == 2'b10 && b == 2'b10) ? 4'b0100 :
                            (a == 2'b11 && b == 2'b11) ? 4'b1001 :
                            (a == 2'b11) ? {2'b00, b} + {2'b00, b} :
                            (b == 2'b11) ? {2'b00, a} + {2'b00, a} :
                            4'b0000;

    always @(*) begin
        product_next = partial_product;
    end

    assign product = product_next;
endmodule