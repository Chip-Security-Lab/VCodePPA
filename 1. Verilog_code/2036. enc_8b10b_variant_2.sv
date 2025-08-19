//SystemVerilog

module enc_8b10b (
    input  wire [7:0] data_in,
    output reg  [9:0] encoded
);
    wire [9:0] mul_a, mul_b;
    wire [19:0] mul_result;

    // Example: using Karatsuba multiplier to multiply two 10-bit values
    // For demonstration, use data_in[4:0] and data_in[7:3] as inputs
    assign mul_a = {5'b0, data_in[4:0]};
    assign mul_b = {5'b0, data_in[7:3]};

    karatsuba_10bit_multiplier u_karatsuba (
        .a(mul_a),
        .b(mul_b),
        .product(mul_result)
    );

    always @* begin
        if (data_in == 8'h00) begin
            encoded = 10'b1001110100;
        end else if (data_in == 8'h01) begin
            encoded = 10'b0111010100;
        end else begin
            // Use lower 10 bits of the Karatsuba multiplication result
            encoded = mul_result[9:0];
        end
    end
endmodule

module karatsuba_10bit_multiplier (
    input  wire [9:0] a,
    input  wire [9:0] b,
    output wire [19:0] product
);
    wire [4:0] a_high = a[9:5];
    wire [4:0] a_low  = a[4:0];
    wire [4:0] b_high = b[9:5];
    wire [4:0] b_low  = b[4:0];

    wire [9:0] z0;
    wire [9:0] z2;
    wire [10:0] z1_temp;
    wire [10:0] z1;

    // z0 = a_low * b_low
    assign z0 = a_low * b_low;

    // z2 = a_high * b_high
    assign z2 = a_high * b_high;

    // (a_low + a_high) * (b_low + b_high)
    wire [5:0] sum_a = a_low + a_high;
    wire [5:0] sum_b = b_low + b_high;
    assign z1_temp = sum_a * sum_b;

    // z1 = (sum_a * sum_b) - z2 - z0
    assign z1 = z1_temp - z2 - z0;

    // product = z2 << 10 + z1 << 5 + z0
    assign product = ({z2,10'b0}) + ({z1,5'b0}) + z0;

endmodule