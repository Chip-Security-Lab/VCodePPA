//SystemVerilog
module enabled_demux (
    input wire [3:0] din_a,                // Multiplier input A (4 bits)
    input wire [3:0] din_b,                // Multiplier input B (4 bits)
    input wire enable,                     // Enable signal
    input wire [1:0] sel,                  // Selection control
    output reg [3:0] q_out                 // Output ports
);
    wire [7:0] karatsuba_product;
    reg selected_bit;

    karatsuba_mult_4bit u_karatsuba_mult_4bit (
        .a(din_a),
        .b(din_b),
        .p(karatsuba_product)
    );

    always @(*) begin
        q_out = 4'b0;                      // Default state
        selected_bit = 1'b0;
        if (enable) begin
            case (sel)
                2'b00: selected_bit = karatsuba_product[0];
                2'b01: selected_bit = karatsuba_product[1];
                2'b10: selected_bit = karatsuba_product[2];
                2'b11: selected_bit = karatsuba_product[3];
                default: selected_bit = 1'b0;
            endcase
            q_out[sel] = selected_bit;
        end
    end
endmodule

module karatsuba_mult_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] p
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z0, z2, z1;
    wire [2:0] a_sum, b_sum;
    wire [3:0] z1_temp;
    wire [7:0] z0_ext, z1_ext, z2_ext;

    assign a_high = a[3:2];
    assign a_low  = a[1:0];
    assign b_high = b[3:2];
    assign b_low  = b[1:0];

    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;

    karatsuba_mult_2bit u_z0 (
        .a(a_low),
        .b(b_low),
        .p(z0)
    );

    karatsuba_mult_2bit u_z2 (
        .a(a_high),
        .b(b_high),
        .p(z2)
    );

    karatsuba_mult_3bit u_z1 (
        .a(a_sum),
        .b(b_sum),
        .p(z1_temp)
    );

    assign z1 = z1_temp - z2 - z0;

    assign z0_ext = {4'b0, z0};
    assign z1_ext = {2'b0, z1, 2'b0};
    assign z2_ext = {z2, 4'b0};

    assign p = z2_ext + z1_ext + z0_ext;
endmodule

module karatsuba_mult_3bit (
    input wire [2:0] a,
    input wire [2:0] b,
    output wire [5:0] p
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [1:0] a_sum, b_sum;
    wire [3:0] z0, z2, z1_temp;
    wire [3:0] z1;
    wire [5:0] z0_ext, z1_ext, z2_ext;

    assign a_high = a[2:1];
    assign a_low  = {1'b0, a[0]};
    assign b_high = b[2:1];
    assign b_low  = {1'b0, b[0]};

    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;

    karatsuba_mult_2bit u_z0 (
        .a(a_low),
        .b(b_low),
        .p(z0)
    );

    karatsuba_mult_2bit u_z2 (
        .a(a_high),
        .b(b_high),
        .p(z2)
    );

    karatsuba_mult_2bit u_z1 (
        .a(a_sum),
        .b(b_sum),
        .p(z1_temp)
    );

    assign z1 = z1_temp - z2 - z0;

    assign z0_ext = {2'b0, z0};
    assign z1_ext = {z1, 2'b0};
    assign z2_ext = {z2, 4'b0};

    assign p = z2_ext + z1_ext + z0_ext;
endmodule

module karatsuba_mult_2bit (
    input wire [1:0] a,
    input wire [1:0] b,
    output wire [3:0] p
);
    wire [0:0] a_high, a_low, b_high, b_low;
    wire [1:0] a_sum, b_sum;
    wire [1:0] z0, z2, z1_temp;
    wire [1:0] z1;
    wire [3:0] z0_ext, z1_ext, z2_ext;

    assign a_high = a[1];
    assign a_low  = a[0];
    assign b_high = b[1];
    assign b_low  = b[0];

    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;

    assign z0 = a_low & b_low;
    assign z2 = a_high & b_high;
    assign z1_temp = a_sum & b_sum;
    assign z1 = z1_temp - z2 - z0;

    assign z0_ext = {2'b00, z0};
    assign z1_ext = {z1, 2'b00};
    assign z2_ext = {z2, 2'b00};

    assign p = (z2 << 2) + (z1 << 1) + z0;
endmodule