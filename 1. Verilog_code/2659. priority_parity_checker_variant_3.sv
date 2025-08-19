//SystemVerilog
module priority_parity_checker (
    input [15:0] data,
    output reg [3:0] parity,
    output reg error
);

wire [15:0] wallace_product;
wallace_multiplier_16bit mult_inst (
    .a(data[7:0]),
    .b(data[15:8]),
    .product(wallace_product)
);

wire [7:0] low_byte = data[7:0];
wire [7:0] high_byte = data[15:8];
wire byte_parity = ^low_byte ^ high_byte;

always @(*) begin
    parity = 4'h0;
    error = 1'b0;
    if (byte_parity) begin
        if (low_byte != 0) begin
            parity = wallace_product[3:0];
            error = 1'b1;
        end
    end
end

endmodule

module wallace_multiplier_16bit (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);

wire [7:0] pp0 = a & {8{b[0]}};
wire [7:0] pp1 = a & {8{b[1]}};
wire [7:0] pp2 = a & {8{b[2]}};
wire [7:0] pp3 = a & {8{b[3]}};
wire [7:0] pp4 = a & {8{b[4]}};
wire [7:0] pp5 = a & {8{b[5]}};
wire [7:0] pp6 = a & {8{b[6]}};
wire [7:0] pp7 = a & {8{b[7]}};

wire [8:0] sum1, carry1;
wire [8:0] sum2, carry2;
wire [8:0] sum3, carry3;

kogge_stone_adder_8bit ks1 (
    .a(pp0),
    .b(pp1 << 1),
    .cin(pp2 << 2),
    .sum(sum1),
    .cout(carry1)
);

kogge_stone_adder_8bit ks2 (
    .a(pp3 << 3),
    .b(pp4 << 4),
    .cin(pp5 << 5),
    .sum(sum2),
    .cout(carry2)
);

kogge_stone_adder_8bit ks3 (
    .a(pp6 << 6),
    .b(pp7 << 7),
    .cin(8'b0),
    .sum(sum3),
    .cout(carry3)
);

wire [9:0] final_sum, final_carry;
kogge_stone_adder_9bit ks4 (
    .a({1'b0, sum1}),
    .b({1'b0, sum2}),
    .cin({1'b0, sum3}),
    .sum(final_sum),
    .cout(final_carry)
);

assign product = final_sum + (final_carry << 1);

endmodule

module kogge_stone_adder_8bit (
    input [7:0] a,
    input [7:0] b,
    input [7:0] cin,
    output [8:0] sum,
    output [8:0] cout
);

wire [7:0] p, g;
wire [7:0] p1, g1;
wire [7:0] p2, g2;
wire [7:0] p3, g3;
wire [7:0] c;

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : ks_loop
        assign p[i] = a[i] ^ b[i];
        assign g[i] = a[i] & b[i];
    end
endgenerate

// First stage
assign p1[0] = p[0];
assign g1[0] = g[0];
generate
    for (i = 1; i < 8; i = i + 1) begin : stage1
        assign p1[i] = p[i] & p[i-1];
        assign g1[i] = (p[i] & g[i-1]) | g[i];
    end
endgenerate

// Second stage
assign p2[0] = p1[0];
assign g2[0] = g1[0];
assign p2[1] = p1[1];
assign g2[1] = g1[1];
generate
    for (i = 2; i < 8; i = i + 1) begin : stage2
        assign p2[i] = p1[i] & p1[i-2];
        assign g2[i] = (p1[i] & g1[i-2]) | g1[i];
    end
endgenerate

// Third stage
assign p3[0] = p2[0];
assign g3[0] = g2[0];
assign p3[1] = p2[1];
assign g3[1] = g2[1];
assign p3[2] = p2[2];
assign g3[2] = g2[2];
assign p3[3] = p2[3];
assign g3[3] = g2[3];
generate
    for (i = 4; i < 8; i = i + 1) begin : stage3
        assign p3[i] = p2[i] & p2[i-4];
        assign g3[i] = (p2[i] & g2[i-4]) | g2[i];
    end
endgenerate

// Generate carry
assign c[0] = cin[0];
generate
    for (i = 1; i < 8; i = i + 1) begin : carry_gen
        assign c[i] = g3[i-1] | (p3[i-1] & cin[0]);
    end
endgenerate

// Generate sum
generate
    for (i = 0; i < 8; i = i + 1) begin : sum_gen
        assign sum[i] = p[i] ^ c[i];
    end
endgenerate

assign sum[8] = c[7];
assign cout = {1'b0, c};

endmodule

module kogge_stone_adder_9bit (
    input [8:0] a,
    input [8:0] b,
    input [8:0] cin,
    output [9:0] sum,
    output [9:0] cout
);

wire [8:0] p, g;
wire [8:0] p1, g1;
wire [8:0] p2, g2;
wire [8:0] p3, g3;
wire [8:0] p4, g4;
wire [8:0] c;

genvar i;
generate
    for (i = 0; i < 9; i = i + 1) begin : ks_loop
        assign p[i] = a[i] ^ b[i];
        assign g[i] = a[i] & b[i];
    end
endgenerate

// First stage
assign p1[0] = p[0];
assign g1[0] = g[0];
generate
    for (i = 1; i < 9; i = i + 1) begin : stage1
        assign p1[i] = p[i] & p[i-1];
        assign g1[i] = (p[i] & g[i-1]) | g[i];
    end
endgenerate

// Second stage
assign p2[0] = p1[0];
assign g2[0] = g1[0];
assign p2[1] = p1[1];
assign g2[1] = g1[1];
generate
    for (i = 2; i < 9; i = i + 1) begin : stage2
        assign p2[i] = p1[i] & p1[i-2];
        assign g2[i] = (p1[i] & g1[i-2]) | g1[i];
    end
endgenerate

// Third stage
assign p3[0] = p2[0];
assign g3[0] = g2[0];
assign p3[1] = p2[1];
assign g3[1] = g2[1];
assign p3[2] = p2[2];
assign g3[2] = g2[2];
assign p3[3] = p2[3];
assign g3[3] = g2[3];
generate
    for (i = 4; i < 9; i = i + 1) begin : stage3
        assign p3[i] = p2[i] & p2[i-4];
        assign g3[i] = (p2[i] & g2[i-4]) | g2[i];
    end
endgenerate

// Fourth stage
assign p4[0] = p3[0];
assign g4[0] = g3[0];
assign p4[1] = p3[1];
assign g4[1] = g3[1];
assign p4[2] = p3[2];
assign g4[2] = g3[2];
assign p4[3] = p3[3];
assign g4[3] = g3[3];
assign p4[4] = p3[4];
assign g4[4] = g3[4];
assign p4[5] = p3[5];
assign g4[5] = g3[5];
assign p4[6] = p3[6];
assign g4[6] = g3[6];
assign p4[7] = p3[7];
assign g4[7] = g3[7];
assign p4[8] = p3[8];
assign g4[8] = g3[8];

// Generate carry
assign c[0] = cin[0];
generate
    for (i = 1; i < 9; i = i + 1) begin : carry_gen
        assign c[i] = g4[i-1] | (p4[i-1] & cin[0]);
    end
endgenerate

// Generate sum
generate
    for (i = 0; i < 9; i = i + 1) begin : sum_gen
        assign sum[i] = p[i] ^ c[i];
    end
endgenerate

assign sum[9] = c[8];
assign cout = {1'b0, c};

endmodule