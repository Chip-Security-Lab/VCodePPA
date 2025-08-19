//SystemVerilog
module lcg_rng (
    input clock,
    input reset,
    output [31:0] random_number
);
    reg [31:0] state;
    
    parameter A = 32'd1664525;
    parameter C = 32'd1013904223;

    wire [63:0] bw_product;

    baugh_wooley_32x32 bw_mul_inst (
        .multiplicand(A),
        .multiplier(state),
        .product(bw_product)
    );

    always @(posedge clock) begin
        if (reset)
            state <= 32'd123456789;
        else
            state <= bw_product[31:0] + C;
    end

    assign random_number = state;
endmodule

module baugh_wooley_32x32 (
    input  [31:0] multiplicand,
    input  [31:0] multiplier,
    output [63:0] product
);
    wire [31:0] a = multiplicand;
    wire [31:0] b = multiplier;
    wire sign_a = a[31];
    wire sign_b = b[31];

    wire [63:0] partial_products [31:0];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_partial_products
            assign partial_products[i] = 
                (i == 31) ? 
                    { {32{a[31] & b[i]}}, a[30:0] & {31{b[i]}}, 1'b1 } : // MSB row, Baugh-Wooley sign extension
                (i == 0)  ? 
                    { {32{a[0] & b[31]}}, a & {32{b[0]}} } : // LSB row, regular AND
                    { {32{a[i] & sign_b}}, a & {32{b[i]}} }; // All other rows, sign extension
        end
    endgenerate

    // Sum all partial products
    wire [63:0] sum_stage1 [15:0];
    wire [63:0] sum_stage2 [7:0];
    wire [63:0] sum_stage3 [3:0];
    wire [63:0] sum_stage4 [1:0];
    wire [63:0] sum_final;

    generate
        for (i = 0; i < 16; i = i + 1) begin : sum1
            assign sum_stage1[i] = partial_products[2*i] + (partial_products[2*i+1] << 1);
        end
        for (i = 0; i < 8; i = i + 1) begin : sum2
            assign sum_stage2[i] = sum_stage1[2*i] + (sum_stage1[2*i+1] << 2);
        end
        for (i = 0; i < 4; i = i + 1) begin : sum3
            assign sum_stage3[i] = sum_stage2[2*i] + (sum_stage2[2*i+1] << 4);
        end
        for (i = 0; i < 2; i = i + 1) begin : sum4
            assign sum_stage4[i] = sum_stage3[2*i] + (sum_stage3[2*i+1] << 8);
        end
    endgenerate

    assign sum_final = sum_stage4[0] + (sum_stage4[1] << 16);

    assign product = sum_final;

endmodule