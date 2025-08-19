module SatSub(input [7:0] a, b, output reg [7:0] res);
    wire [7:0] product;
    wire [7:0] diff_final;
    
    KaratsubaMultiplier km (
        .a(a),
        .b(b),
        .product(product)
    );
    
    SaturationLogic sl (
        .a(a),
        .b(b),
        .product(product),
        .diff_final(diff_final)
    );
    
    always @(*) begin
        res = diff_final;
    end
endmodule

module KaratsubaMultiplier(
    input [7:0] a,
    input [7:0] b,
    output [7:0] product
);
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low = b[3:0];
    
    wire [7:0] z0 = a_low * b_low;
    wire [7:0] z2 = a_high * b_high;
    wire [7:0] z1 = (a_high + a_low) * (b_high + b_low) - z0 - z2;
    
    wire [7:0] z2_shifted = {z2, 8'b0};
    wire [7:0] z1_shifted = {4'b0, z1[7:4], z1[3:0]};
    
    assign product = z2_shifted + z1_shifted + z0;
endmodule

module SaturationLogic(
    input [7:0] a,
    input [7:0] b,
    input [7:0] product,
    output [7:0] diff_final
);
    wire [7:0] diff = a - b;
    wire [7:0] diff_abs = (diff[7]) ? ~diff + 1 : diff;
    wire [7:0] diff_sign = {8{diff[7]}};
    wire [7:0] diff_comp = diff_abs & diff_sign;
    wire [7:0] diff_sel = (a >= b) ? diff : 8'h0;
    
    assign diff_final = diff_sel & product;
endmodule