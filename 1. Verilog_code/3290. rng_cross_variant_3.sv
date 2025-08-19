//SystemVerilog
module rng_cross_10(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  out_rnd
);
    reg [7:0] state_1, state_2;
    wire [15:0] wallace_mult_result;

    // Wallace Tree Multiplier Instance
    wallace_multiplier_8x8 wallace_mult_u (
        .a(state_1),
        .b(state_2),
        .product(wallace_mult_result)
    );

    always @(posedge clk) begin
        if (rst) begin
            state_1 <= 8'hF0;
            state_2 <= 8'h0F;
        end else if (en) begin
            state_1 <= {state_1[6:0], state_2[7] ^ state_1[0]};
            state_2 <= {state_2[6:0], state_1[7] ^ state_2[0]};
        end
    end

    always @(*) begin
        out_rnd = wallace_mult_result[7:0] ^ wallace_mult_result[15:8];
    end
endmodule

module wallace_multiplier_8x8(
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);
    wire [7:0] pp [7:0];
    assign pp[0] = a & {8{b[0]}};
    assign pp[1] = a & {8{b[1]}};
    assign pp[2] = a & {8{b[2]}};
    assign pp[3] = a & {8{b[3]}};
    assign pp[4] = a & {8{b[4]}};
    assign pp[5] = a & {8{b[5]}};
    assign pp[6] = a & {8{b[6]}};
    assign pp[7] = a & {8{b[7]}};

    // First reduction layer
    wire [7:0] s1_0, s1_1, s1_2, s1_3, c1_0, c1_1, c1_2, c1_3;
    // Column 0
    assign product[0] = pp[0][0];
    // Column 1
    half_adder ha1_1 (.a(pp[0][1]), .b(pp[1][0]), .sum(s1_0[0]), .carry(c1_0[0]));
    assign product[1] = s1_0[0];
    // Column 2
    full_adder fa1_2 (.a(pp[0][2]), .b(pp[1][1]), .cin(pp[2][0]), .sum(s1_1[0]), .carry(c1_1[0]));
    assign product[2] = s1_1[0];
    // Column 3
    full_adder fa1_3 (.a(pp[0][3]), .b(pp[1][2]), .cin(pp[2][1]), .sum(s1_2[0]), .carry(c1_2[0]));
    half_adder ha1_3 (.a(s1_2[0]), .b(pp[3][0]), .sum(s1_3[0]), .carry(c1_3[0]));
    assign product[3] = s1_3[0];
    // Column 4
    full_adder fa1_4 (.a(pp[0][4]), .b(pp[1][3]), .cin(pp[2][2]), .sum(s1_0[1]), .carry(c1_0[1]));
    full_adder fa1_4b(.a(s1_0[1]), .b(pp[3][1]), .cin(pp[4][0]), .sum(s1_1[1]), .carry(c1_1[1]));
    assign product[4] = s1_1[1];
    // Column 5
    full_adder fa1_5 (.a(pp[0][5]), .b(pp[1][4]), .cin(pp[2][3]), .sum(s1_2[1]), .carry(c1_2[1]));
    full_adder fa1_5b(.a(s1_2[1]), .b(pp[3][2]), .cin(pp[4][1]), .sum(s1_3[1]), .carry(c1_3[1]));
    half_adder ha1_5 (.a(s1_3[1]), .b(pp[5][0]), .sum(s1_0[2]), .carry(c1_0[2]));
    assign product[5] = s1_0[2];
    // Column 6
    full_adder fa1_6 (.a(pp[0][6]), .b(pp[1][5]), .cin(pp[2][4]), .sum(s1_1[2]), .carry(c1_1[2]));
    full_adder fa1_6b(.a(s1_1[2]), .b(pp[3][3]), .cin(pp[4][2]), .sum(s1_2[2]), .carry(c1_2[2]));
    full_adder fa1_6c(.a(s1_2[2]), .b(pp[5][1]), .cin(pp[6][0]), .sum(s1_3[2]), .carry(c1_3[2]));
    assign product[6] = s1_3[2];
    // Column 7
    full_adder fa1_7 (.a(pp[0][7]), .b(pp[1][6]), .cin(pp[2][5]), .sum(s1_0[3]), .carry(c1_0[3]));
    full_adder fa1_7b(.a(s1_0[3]), .b(pp[3][4]), .cin(pp[4][3]), .sum(s1_1[3]), .carry(c1_1[3]));
    full_adder fa1_7c(.a(s1_1[3]), .b(pp[5][2]), .cin(pp[6][1]), .sum(s1_2[3]), .carry(c1_2[3]));
    half_adder ha1_7 (.a(s1_2[3]), .b(pp[7][0]), .sum(s1_3[3]), .carry(c1_3[3]));
    assign product[7] = s1_3[3];
    // Column 8
    full_adder fa1_8 (.a(pp[1][7]), .b(pp[2][6]), .cin(pp[3][5]), .sum(s1_0[4]), .carry(c1_0[4]));
    full_adder fa1_8b(.a(s1_0[4]), .b(pp[4][4]), .cin(pp[5][3]), .sum(s1_1[4]), .carry(c1_1[4]));
    full_adder fa1_8c(.a(s1_1[4]), .b(pp[6][2]), .cin(pp[7][1]), .sum(s1_2[4]), .carry(c1_2[4]));
    assign product[8] = s1_2[4];
    // Column 9
    full_adder fa1_9 (.a(pp[2][7]), .b(pp[3][6]), .cin(pp[4][5]), .sum(s1_3[4]), .carry(c1_3[4]));
    full_adder fa1_9b(.a(s1_3[4]), .b(pp[5][4]), .cin(pp[6][3]), .sum(s1_0[5]), .carry(c1_0[5]));
    half_adder ha1_9 (.a(s1_0[5]), .b(pp[7][2]), .sum(s1_1[5]), .carry(c1_1[5]));
    assign product[9] = s1_1[5];
    // Column 10
    full_adder fa1_10 (.a(pp[3][7]), .b(pp[4][6]), .cin(pp[5][5]), .sum(s1_2[5]), .carry(c1_2[5]));
    full_adder fa1_10b(.a(s1_2[5]), .b(pp[6][4]), .cin(pp[7][3]), .sum(s1_3[5]), .carry(c1_3[5]));
    assign product[10] = s1_3[5];
    // Column 11
    full_adder fa1_11 (.a(pp[4][7]), .b(pp[5][6]), .cin(pp[6][5]), .sum(s1_0[6]), .carry(c1_0[6]));
    half_adder ha1_11 (.a(s1_0[6]), .b(pp[7][4]), .sum(s1_1[6]), .carry(c1_1[6]));
    assign product[11] = s1_1[6];
    // Column 12
    full_adder fa1_12 (.a(pp[5][7]), .b(pp[6][6]), .cin(pp[7][5]), .sum(s1_2[6]), .carry(c1_2[6]));
    assign product[12] = s1_2[6];
    // Column 13
    half_adder ha1_13 (.a(pp[6][7]), .b(pp[7][6]), .sum(s1_3[6]), .carry(c1_3[6]));
    assign product[13] = s1_3[6];
    // Column 14
    assign product[14] = pp[7][7];
    // Column 15
    assign product[15] = 1'b0;
endmodule

module half_adder(
    input  a,
    input  b,
    output sum,
    output carry
);
    assign sum = a ^ b;
    assign carry = a & b;
endmodule

module full_adder(
    input  a,
    input  b,
    input  cin,
    output sum,
    output carry
);
    assign sum = a ^ b ^ cin;
    assign carry = (a & b) | (a & cin) | (b & cin);
endmodule