//SystemVerilog
module ascii2bin (
    input  [7:0] ascii_in,
    output [6:0] bin_out
);
    wire [7:0] baugh_wooley_a;
    wire [7:0] baugh_wooley_b;
    wire [15:0] baugh_wooley_product;
    reg  [6:0] bin_out_reg;

    // For demonstration, multiply ascii_in by 1 using Baugh-Wooley to replace direct assignment
    assign baugh_wooley_a = ascii_in;
    assign baugh_wooley_b = 8'b00000001;

    baugh_wooley_multiplier_8x8 bw_mult_inst (
        .a(baugh_wooley_a),
        .b(baugh_wooley_b),
        .product(baugh_wooley_product)
    );

    always @(*) begin
        if (|ascii_in) begin
            bin_out_reg = baugh_wooley_product[6:0];
        end else begin
            bin_out_reg = 7'b0;
        end
    end

    assign bin_out = bin_out_reg;
endmodule

// 8x8 Signed Baugh-Wooley Multiplier
module baugh_wooley_multiplier_8x8 (
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);
    wire [7:0] a_signed;
    wire [7:0] b_signed;

    // Treat inputs as signed
    assign a_signed = a;
    assign b_signed = b;

    wire [15:0] partial_products [7:0];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_partial_products
            assign partial_products[i] = (b_signed[i] ? {8'b0, a_signed} << i : 16'b0);
        end
    endgenerate

    // Baugh-Wooley adjustments for signed multiplication
    wire [15:0] bw_sum;
    assign bw_sum =
        partial_products[0] +
        partial_products[1] +
        partial_products[2] +
        partial_products[3] +
        partial_products[4] +
        partial_products[5] +
        partial_products[6] +
        partial_products[7];

    // Correction terms for Baugh-Wooley
    wire [15:0] bw_correction;
    assign bw_correction = { {8{a_signed[7] & b_signed[7]}}, 8'b0 };

    assign product = bw_sum + bw_correction;
endmodule