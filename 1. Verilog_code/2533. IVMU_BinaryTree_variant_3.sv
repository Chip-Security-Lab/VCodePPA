//SystemVerilog
// Baugh-Wooley Signed Multiplier (4x4)
module BaughWooleyMultiplier_4x4 (
    input [3:0] A,
    input [3:0] B,
    output [7:0] P
);

// Partial products and correction terms based on Baugh-Wooley algorithm
// For N=4:
// P = Sum(A[i]B[j]*2^(i+j)) for i,j in 0..2
//   + Sum(~A[3]B[j]*2^(3+j)) for j in 0..2
//   + Sum(A[i]~B[3]*2^(i+3)) for i in 0..2
//   + A[3]B[3]*2^6
//   + A[3]*2^3 + B[3]*2^3 + 2^7 -- corrections

// Partial products at different weights (powers of 2)
wire pp_w0 = A[0] & B[0];

wire pp_w1_0 = A[0] & B[1];
wire pp_w1_1 = A[1] & B[0];

wire pp_w2_0 = A[0] & B[2];
wire pp_w2_1 = A[1] & B[1];
wire pp_w2_2 = A[2] & B[0];

wire pp_w3_0 = A[1] & B[2];
wire pp_w3_1 = A[2] & B[1];
wire pp_w3_2 = (~A[3]) & B[0];
wire pp_w3_3 = A[0] & (~B[3]);

wire pp_w4_0 = A[2] & B[2];
wire pp_w4_1 = (~A[3]) & B[1];
wire pp_w4_2 = A[1] & (~B[3]);

wire pp_w5_0 = (~A[3]) & B[2];
wire pp_w5_1 = A[2] & (~B[3]);

wire pp_w6_0 = A[3] & B[3];

// Correction terms at specific weights
wire corr_w3_A = A[3];
wire corr_w3_B = B[3];
wire corr_w7 = 1'b1; // Correction 2^7

// Summing partial products and corrections using vector addition
// This implicitly creates an adder tree (like Wallace tree or array multiplier)
wire [7:0] sum_vec_0;
wire [7:0] sum_vec_1;
wire [7:0] sum_vec_2;
wire [7:0] sum_vec_3;
wire [7:0] sum_vec_4;
wire [7:0] sum_vec_5;
wire [7:0] sum_vec_6;
wire [7:0] sum_vec_7;

assign sum_vec_0 = {7'b0, pp_w0};
assign sum_vec_1 = {6'b0, pp_w1_0, pp_w1_1, 1'b0};
assign sum_vec_2 = {5'b0, pp_w2_0, pp_w2_1, pp_w2_2, 2'b0};
assign sum_vec_3 = {4'b0, pp_w3_0, pp_w3_1, pp_w3_2, pp_w3_3, corr_w3_A, corr_w3_B, 3'b0};
assign sum_vec_4 = {3'b0, pp_w4_0, pp_w4_1, pp_w4_2, 4'b0};
assign sum_vec_5 = {2'b0, pp_w5_0, pp_w5_1, 5'b0};
assign sum_vec_6 = {1'b0, pp_w6_0, 6'b0};
assign sum_vec_7 = {corr_w7, 7'b0};

assign P = sum_vec_0 + sum_vec_1 + sum_vec_2 + sum_vec_3 + sum_vec_4 + sum_vec_5 + sum_vec_6 + sum_vec_7;

endmodule