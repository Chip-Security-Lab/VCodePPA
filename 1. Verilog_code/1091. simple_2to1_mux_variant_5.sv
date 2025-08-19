//SystemVerilog
module simple_2to1_mux (
    input wire [7:0] data0, 
    input wire [7:0] data1,      
    input wire sel,               
    output wire [15:0] mux_out           
);

    wire [15:0] karatsuba_product_data0;
    wire [15:0] karatsuba_product_data1;

    karatsuba_multiplier_8bit u_karatsuba_data0 (
        .a(data0),
        .b(data0),
        .product(karatsuba_product_data0)
    );

    karatsuba_multiplier_8bit u_karatsuba_data1 (
        .a(data1),
        .b(data1),
        .product(karatsuba_product_data1)
    );

    reg [15:0] mux_out_reg;

    always @(*) begin
        if (sel) begin
            mux_out_reg = karatsuba_product_data1;
        end else begin
            mux_out_reg = karatsuba_product_data0;
        end
    end

    assign mux_out = mux_out_reg;

endmodule

module karatsuba_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z2, z1;
    wire [7:0] a_sum, b_sum;
    wire [15:0] z0_ext, z1_ext, z2_ext, z1_shifted, z2_shifted;

    assign a_high = a[7:4];
    assign a_low  = a[3:0];
    assign b_high = b[7:4];
    assign b_low  = b[3:0];

    assign a_sum = {1'b0, a_high} + {1'b0, a_low};
    assign b_sum = {1'b0, b_high} + {1'b0, b_low};

    // z0 = a_low * b_low
    karatsuba_multiplier_4bit u_z0 (
        .a(a_low),
        .b(b_low),
        .product(z0)
    );

    // z2 = a_high * b_high
    karatsuba_multiplier_4bit u_z2 (
        .a(a_high),
        .b(b_high),
        .product(z2)
    );

    // z1 = (a_low + a_high) * (b_low + b_high)
    karatsuba_multiplier_5bit u_z1 (
        .a(a_sum),
        .b(b_sum),
        .product(z1)
    );

    assign z0_ext = {8'b0, z0};
    assign z2_ext = {z2, 8'b0};
    assign z1_ext = {8'b0, z1} - z0_ext - z2_ext;
    assign z1_shifted = z1_ext << 4;
    assign z2_shifted = z2_ext;

    assign product = z2_shifted + z1_shifted + z0_ext;

endmodule

module karatsuba_multiplier_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] product
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z0, z2, z1;
    wire [2:0] a_sum, b_sum;
    wire [7:0] z0_ext, z2_ext, z1_ext, z1_shifted, z2_shifted;

    assign a_high = a[3:2];
    assign a_low  = a[1:0];
    assign b_high = b[3:2];
    assign b_low  = b[1:0];

    assign a_sum = {1'b0, a_high} + {1'b0, a_low};
    assign b_sum = {1'b0, b_high} + {1'b0, b_low};

    // z0 = a_low * b_low
    assign z0 = a_low * b_low;

    // z2 = a_high * b_high
    assign z2 = a_high * b_high;

    // z1 = (a_low + a_high) * (b_low + b_high)
    assign z1 = a_sum * b_sum;

    assign z0_ext = {4'b0, z0};
    assign z2_ext = {z2, 4'b0};
    assign z1_ext = {4'b0, z1} - z0_ext - z2_ext;
    assign z1_shifted = z1_ext << 2;
    assign z2_shifted = z2_ext;

    assign product = z2_shifted + z1_shifted + z0_ext;

endmodule

module karatsuba_multiplier_5bit (
    input wire [4:0] a,
    input wire [4:0] b,
    output wire [7:0] product
);
    // For 5-bit multiplication, use direct multiplication for simplicity and timing
    assign product = a * b;
endmodule