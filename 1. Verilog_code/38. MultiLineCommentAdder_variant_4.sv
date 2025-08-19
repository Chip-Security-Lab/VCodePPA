//SystemVerilog
module adder_8bit_rca (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire       cin,
    output wire [7:0] sum,
    output wire       cout
);

// This module implements an 8-bit Carry-Select Adder (CSA)
// divided into two 4-bit blocks for improved performance over RCA.

// --- Block 0 (Bits 0-3) - Ripple Carry Adder ---
// This block calculates sum and carry-out based on the external cin.
wire [3:0] block0_sum;
wire block0_cout;
wire [4:0] block0_carries; // block0_carries[0] is cin

assign block0_carries[0] = cin;

// Full Adder for Bit 0
assign block0_sum[0] = a[0] ^ b[0] ^ block0_carries[0];
assign block0_carries[1] = (a[0] & b[0]) | ((a[0] ^ b[0]) & block0_carries[0]);

// Full Adder for Bit 1
assign block0_sum[1] = a[1] ^ b[1] ^ block0_carries[1];
assign block0_carries[2] = (a[1] & b[1]) | ((a[1] ^ b[1]) & block0_carries[1]);

// Full Adder for Bit 2
assign block0_sum[2] = a[2] ^ b[2] ^ block0_carries[2];
assign block0_carries[3] = (a[2] & b[2]) | ((a[2] ^ b[2]) & block0_carries[2]);

// Full Adder for Bit 3
assign block0_sum[3] = a[3] ^ b[3] ^ block0_carries[3];
assign block0_carries[4] = (a[3] & b[3]) | ((a[3] ^ b[3]) & block0_carries[3]);

// Carry-out from Block 0
assign block0_cout = block0_carries[4];


// --- Block 1 (Bits 4-7) - Parallel Ripple Carry Adders ---
// This block calculates sum and carry-out twice in parallel:
// once assuming carry-in from Block 0 is 0, and once assuming it is 1.

// Assume carry-in from Block 0 is 0
wire [3:0] block1_sum_cin0;
wire block1_cout_cin0;
wire [4:0] block1_carries_cin0; // block1_carries_cin0[0] is 0

assign block1_carries_cin0[0] = 1'b0; // Assumed carry-in = 0
// Full Adder for Bit 4
assign block1_sum_cin0[0] = a[4] ^ b[4] ^ block1_carries_cin0[0];
assign block1_carries_cin0[1] = (a[4] & b[4]) | ((a[4] ^ b[4]) & block1_carries_cin0[0]);
// Full Adder for Bit 5
assign block1_sum_cin0[1] = a[5] ^ b[5] ^ block1_carries_cin0[1];
assign block1_carries_cin0[2] = (a[5] & b[5]) | ((a[5] ^ b[5]) & block1_carries_cin0[1]);
// Full Adder for Bit 6
assign block1_sum_cin0[2] = a[6] ^ b[6] ^ block1_carries_cin0[2];
assign block1_carries_cin0[3] = (a[6] & b[6]) | ((a[6] ^ b[6]) & block1_carries_cin0[2]);
// Full Adder for Bit 7
assign block1_sum_cin0[3] = a[7] ^ b[7] ^ block1_carries_cin0[3];
assign block1_carries_cin0[4] = (a[7] & b[7]) | ((a[7] ^ b[7]) & block1_carries_cin0[3]);

assign block1_cout_cin0 = block1_carries_cin0[4];

// Assume carry-in from Block 0 is 1
wire [3:0] block1_sum_cin1;
wire block1_cout_cin1;
wire [4:0] block1_carries_cin1; // block1_carries_cin1[0] is 1

assign block1_carries_cin1[0] = 1'b1; // Assumed carry-in = 1
// Full Adder for Bit 4
assign block1_sum_cin1[0] = a[4] ^ b[4] ^ block1_carries_cin1[0];
assign block1_carries_cin1[1] = (a[4] & b[4]) | ((a[4] ^ b[4]) & block1_carries_cin1[0]);
// Full Adder for Bit 5
assign block1_sum_cin1[1] = a[5] ^ b[5] ^ block1_carries_cin1[1];
assign block1_carries_cin1[2] = (a[5] & b[5]) | ((a[5] ^ b[5]) & block1_carries_cin1[1]);
// Full Adder for Bit 6
assign block1_sum_cin1[2] = a[6] ^ b[6] ^ block1_carries_cin1[2];
assign block1_carries_cin1[3] = (a[6] & b[6]) | ((a[6] ^ b[6]) & block1_carries_cin1[2]);
// Full Adder for Bit 7
assign block1_sum_cin1[3] = a[7] ^ b[7] ^ block1_carries_cin1[3];
assign block1_carries_cin1[4] = (a[7] & b[7]) | ((a[7] ^ b[7]) & block1_carries_cin1[3]);

assign block1_cout_cin1 = block1_carries_cin1[4];


// --- Selection Logic ---
// Select the correct sum bits and carry-out for Block 1
// based on the actual carry-out from Block 0 (block0_cout).

// Lower bits of the sum come directly from Block 0
assign sum[3:0] = block0_sum[3:0];

// Upper bits of the sum are selected
assign sum[4] = block0_cout ? block1_sum_cin1[0] : block1_sum_cin0[0];
assign sum[5] = block0_cout ? block1_sum_cin1[1] : block1_sum_cin0[1];
assign sum[6] = block0_cout ? block1_sum_cin1[2] : block1_sum_cin0[2];
assign sum[7] = block0_cout ? block1_sum_cin1[3] : block1_sum_cin0[3];

// Final carry-out is selected
assign cout = block0_cout ? block1_cout_cin1 : block1_cout_cin0;

endmodule