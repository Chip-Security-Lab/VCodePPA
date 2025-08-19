//SystemVerilog
module dadda_multiplier_4bit (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);

    // Partial products generation
    wire [3:0] pp0, pp1, pp2, pp3;
    assign pp0 = a & {4{b[0]}};
    assign pp1 = a & {4{b[1]}};
    assign pp2 = a & {4{b[2]}};
    assign pp3 = a & {4{b[3]}};

    // Stage 1: 4x4 to 3x4
    wire [4:0] s1_0, c1_0;
    wire [4:0] s1_1, c1_1;
    
    // First column reduction
    half_adder ha1_0(.a(pp0[1]), .b(pp1[0]), .sum(s1_0[0]), .cout(c1_0[0]));
    full_adder fa1_0(.a(pp0[2]), .b(pp1[1]), .cin(pp2[0]), .sum(s1_0[1]), .cout(c1_0[1]));
    full_adder fa1_1(.a(pp0[3]), .b(pp1[2]), .cin(pp2[1]), .sum(s1_0[2]), .cout(c1_0[2]));
    full_adder fa1_2(.a(pp1[3]), .b(pp2[2]), .cin(pp3[1]), .sum(s1_0[3]), .cout(c1_0[3]));
    assign s1_0[4] = pp3[2];
    assign c1_0[4] = pp3[3];

    // Second column reduction
    half_adder ha1_2(.a(pp2[3]), .b(pp3[0]), .sum(s1_1[0]), .cout(c1_1[0]));
    assign s1_1[1] = pp3[1];
    assign s1_1[2] = pp3[2];
    assign s1_1[3] = pp3[3];
    assign s1_1[4] = 1'b0;
    assign c1_1[1] = 1'b0;
    assign c1_1[2] = 1'b0;
    assign c1_1[3] = 1'b0;
    assign c1_1[4] = 1'b0;

    // Stage 2: 3x4 to 2x4
    wire [5:0] s2, c2;
    
    // Final reduction
    half_adder ha2_0(.a(s1_0[0]), .b(c1_0[0]), .sum(s2[0]), .cout(c2[0]));
    full_adder fa2_0(.a(s1_0[1]), .b(c1_0[1]), .cin(s1_1[0]), .sum(s2[1]), .cout(c2[1]));
    full_adder fa2_1(.a(s1_0[2]), .b(c1_0[2]), .cin(s1_1[1]), .sum(s2[2]), .cout(c2[2]));
    full_adder fa2_2(.a(s1_0[3]), .b(c1_0[3]), .cin(s1_1[2]), .sum(s2[3]), .cout(c2[3]));
    full_adder fa2_3(.a(s1_0[4]), .b(c1_0[4]), .cin(s1_1[3]), .sum(s2[4]), .cout(c2[4]));
    assign s2[5] = s1_1[4];
    assign c2[5] = 1'b0;

    // Final addition
    assign product[0] = pp0[0];
    assign product[1] = s2[0];
    assign product[2] = s2[1];
    assign product[3] = s2[2];
    assign product[4] = s2[3];
    assign product[5] = s2[4];
    assign product[6] = s2[5];
    assign product[7] = c2[5];

endmodule

module half_adder (
    input a,
    input b,
    output sum,
    output cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    wire s1, c1, c2;
    half_adder ha1(.a(a), .b(b), .sum(s1), .cout(c1));
    half_adder ha2(.a(s1), .b(cin), .sum(sum), .cout(c2));
    assign cout = c1 | c2;
endmodule