//SystemVerilog
module IterNor(
    input  [7:0] a,
    input  [7:0] b,
    output reg [7:0] y,
    output reg [15:0] wallace_prod
);

    // Bitwise NOR
    always @(*) begin
        y[0] = ~(a[0] | b[0]);
        y[1] = ~(a[1] | b[1]);
        y[2] = ~(a[2] | b[2]);
        y[3] = ~(a[3] | b[3]);
        y[4] = ~(a[4] | b[4]);
        y[5] = ~(a[5] | b[5]);
        y[6] = ~(a[6] | b[6]);
        y[7] = ~(a[7] | b[7]);
    end

    // Wallace Tree Multiplier
    wire [7:0] partial_product [7:0];
    wire [15:0] level1_sum [3:0], level1_carry [3:0];
    wire [15:0] level2_sum [1:0], level2_carry [1:0];
    wire [15:0] level3_sum, level3_carry;
    integer i;

    // Generate Partial Products
    generate
        genvar gi;
        for (gi = 0; gi < 8; gi = gi + 1) begin : gen_partial
            assign partial_product[gi] = b & {8{a[gi]}};
        end
    endgenerate

    // Align partial products to form 16-bit values
    wire [15:0] pp0 = {8'b0, partial_product[0]};
    wire [15:0] pp1 = {7'b0, partial_product[1], 1'b0};
    wire [15:0] pp2 = {6'b0, partial_product[2], 2'b0};
    wire [15:0] pp3 = {5'b0, partial_product[3], 3'b0};
    wire [15:0] pp4 = {4'b0, partial_product[4], 4'b0};
    wire [15:0] pp5 = {3'b0, partial_product[5], 5'b0};
    wire [15:0] pp6 = {2'b0, partial_product[6], 6'b0};
    wire [15:0] pp7 = {1'b0, partial_product[7], 7'b0};

    // First Wallace Tree Level (full-adder style reduction)
    WallaceAdder3 wa1_0 (.a(pp0), .b(pp1), .c(pp2), .sum(level1_sum[0]), .carry(level1_carry[0]));
    WallaceAdder3 wa1_1 (.a(pp3), .b(pp4), .c(pp5), .sum(level1_sum[1]), .carry(level1_carry[1]));
    WallaceAdder2 wa1_2 (.a(pp6), .b(pp7), .sum(level1_sum[2]), .carry(level1_carry[2]));
    assign level1_sum[3] = 16'b0;
    assign level1_carry[3] = 16'b0;

    // Second Wallace Tree Level
    WallaceAdder3 wa2_0 (.a(level1_sum[0]), .b(level1_sum[1]), .c(level1_sum[2]), .sum(level2_sum[0]), .carry(level2_carry[0]));
    WallaceAdder3 wa2_1 (.a(level1_carry[0]<<1), .b(level1_carry[1]<<1), .c(level1_carry[2]<<1), .sum(level2_sum[1]), .carry(level2_carry[1]));

    // Third Wallace Tree Level
    WallaceAdder3 wa3_0 (
        .a(level2_sum[0]), 
        .b(level2_sum[1]), 
        .c((level2_carry[0] << 1) + (level2_carry[1] << 1)), 
        .sum(level3_sum), 
        .carry(level3_carry)
    );

    // Final addition
    always @(*) begin
        wallace_prod = level3_sum + (level3_carry << 1);
    end

endmodule

module WallaceAdder3(
    input  [15:0] a,
    input  [15:0] b,
    input  [15:0] c,
    output [15:0] sum,
    output [15:0] carry
);
    assign sum   = a ^ b ^ c;
    assign carry = (a & b) | (a & c) | (b & c);
endmodule

module WallaceAdder2(
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] sum,
    output [15:0] carry
);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule