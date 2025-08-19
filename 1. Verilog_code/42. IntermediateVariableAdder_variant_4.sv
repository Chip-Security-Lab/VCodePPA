//SystemVerilog
module brent_kung_adder_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire       cin,
    output wire [7:0] sum,
    output wire      cout
);

// Wires for generate and propagate signals at different levels (Forward Pass)
wire [7:0] p_l0, g_l0; // Level 0: per-bit generate and propagate (P=A^B, G=A&B)
wire [7:0] p_l1, g_l1; // Level 1: combine adjacent bits (distance 1)
wire [7:0] p_l2, g_l2; // Level 2: combine blocks of size 2 (distance 2)
wire [7:0] p_l3, g_l3; // Level 3: combine blocks of size 4 (distance 4)

// Wires for carries (Backward Pass)
// carry_in[i] is the carry-in to bit i
wire [8:0] carry_in; // carry_in[0] is cin, carry_in[8] is cout (cout)

//------------------------------------------------------------------------------
// Level 0: Initial Generate and Propagate
// P[i] = a[i] ^ b[i]
// G[i] = a[i] & b[i]
//------------------------------------------------------------------------------
assign p_l0 = a ^ b;
assign g_l0 = a & b;

//------------------------------------------------------------------------------
// Level 1: Combine adjacent bits (distance 1)
// Black cells (i=1,3,5,7): (P_out, G_out) = (P_right & P_left, G_right | (P_right & G_left))
// Gray cells (i=0,2,4,6): Pass-through
//------------------------------------------------------------------------------
// Gray cells
assign p_l1[0] = p_l0[0];
assign g_l1[0] = g_l0[0];
assign p_l1[2] = p_l0[2];
assign g_l1[2] = g_l0[2];
assign p_l1[4] = p_l0[4];
assign g_l1[4] = g_l0[4];
assign p_l1[6] = p_l0[6];
assign g_l1[6] = g_l0[6];

// Black cells
assign p_l1[1] = p_l0[1] & p_l0[0];
assign g_l1[1] = g_l0[1] | (p_l0[1] & g_l0[0]);
assign p_l1[3] = p_l0[3] & p_l0[2];
assign g_l1[3] = g_l0[3] | (p_l0[3] & g_l0[2]);
assign p_l1[5] = p_l0[5] & p_l0[4];
assign g_l1[5] = g_l0[5] | (p_l0[5] & g_l0[4]);
assign p_l1[7] = p_l0[7] & p_l0[6];
assign g_l1[7] = g_l0[7] | (p_l0[7] & g_l0[6]);

//------------------------------------------------------------------------------
// Level 2: Combine blocks of size 2 (distance 2)
// Black cells (i=3,7): Combine with results from i-2 from Level 1
// Gray cells (i=0,1,2,4,5,6): Pass-through from Level 1
//------------------------------------------------------------------------------
// Gray cells
assign p_l2[0] = p_l1[0];
assign g_l2[0] = g_l1[0];
assign p_l2[1] = p_l1[1];
assign g_l2[1] = g_l1[1];
assign p_l2[2] = p_l1[2];
assign g_l2[2] = g_l1[2];
assign p_l2[4] = p_l1[4];
assign g_l2[4] = g_l1[4];
assign p_l2[5] = p_l1[5];
assign g_l2[5] = g_l1[5];
assign p_l2[6] = p_l1[6];
assign g_l2[6] = g_l1[6];

// Black cells
assign p_l2[3] = p_l1[3] & p_l1[1]; // Combines block [2,3] with [0,1] -> [0,3]
assign g_l2[3] = g_l1[3] | (p_l1[3] & g_l1[1]);
assign p_l2[7] = p_l1[7] & p_l1[5]; // Combines block [6,7] with [4,5] -> [4,7]
assign g_l2[7] = g_l1[7] | (p_l1[7] & g_l1[5]);

//------------------------------------------------------------------------------
// Level 3: Combine blocks of size 4 (distance 4)
// Black cell (i=7): Combine with result from i-4 from Level 2
// Gray cells (i=0..6): Pass-through from Level 2
//------------------------------------------------------------------------------
// Gray cells
assign p_l3[0] = p_l2[0];
assign g_l3[0] = g_l2[0];
assign p_l3[1] = p_l2[1];
assign g_l3[1] = g_l2[1];
assign p_l3[2] = p_l2[2];
assign g_l3[2] = g_l2[2];
assign p_l3[3] = p_l2[3]; // P_l2[3]/G_l2[3] cover block [0,3]
assign g_l3[3] = g_l2[3];
assign p_l3[4] = p_l2[4];
assign g_l3[4] = g_l2[4];
assign p_l3[5] = p_l2[5];
assign g_l3[5] = g_l2[5];
assign p_l3[6] = p_l2[6];
assign g_l3[6] = g_l2[6];

// Black cell
assign p_l3[7] = p_l2[7] & p_l2[3]; // Combines block [4,7] with [0,3] -> [0,7]
assign g_l3[7] = g_l2[7] | (p_l2[7] & g_l2[3]);

//------------------------------------------------------------------------------
// Carry computation (Backward Pass)
// carry_in[i] = G_block | (P_block & carry_in_block)
//------------------------------------------------------------------------------
assign carry_in[0] = cin;
// Carry into bit 1 (from bit 0)
assign carry_in[1] = g_l0[0] | (p_l0[0] & carry_in[0]);
// Carry into bit 2 (from block [0,1]) - Uses P/G from Level 1, index 1
assign carry_in[2] = g_l1[1] | (p_l1[1] & carry_in[0]);
// Carry into bit 3 (from bit 2, depends on carry_in[2]) - Uses P/G from Level 0, index 2
assign carry_in[3] = g_l0[2] | (p_l0[2] & carry_in[2]);
// Carry into bit 4 (from block [0,3]) - Uses P/G from Level 2, index 3
assign carry_in[4] = g_l2[3] | (p_l2[3] & carry_in[0]);
// Carry into bit 5 (from bit 4, depends on carry_in[4]) - Uses P/G from Level 0, index 4
assign carry_in[5] = g_l0[4] | (p_l0[4] & carry_in[4]);
// Carry into bit 6 (from block [4,5], depends on carry_in[4]) - Uses P/G from Level 1, index 5
assign carry_in[6] = g_l1[5] | (p_l1[5] & carry_in[4]);
// Carry into bit 7 (from bit 6, depends on carry_in[6]) - Uses P/G from Level 0, index 6
assign carry_in[7] = g_l0[6] | (p_l0[6] & carry_in[6]);
// Carry out (from block [0,7]) - Uses P/G from Level 3, index 7
assign carry_in[8] = g_l3[7] | (p_l3[7] & carry_in[0]);

//------------------------------------------------------------------------------
// Sum computation: Sum[i] = P_l0[i] ^ carry_in[i]
//------------------------------------------------------------------------------
assign sum[0] = p_l0[0] ^ carry_in[0];
assign sum[1] = p_l0[1] ^ carry_in[1];
assign sum[2] = p_l0[2] ^ carry_in[2];
assign sum[3] = p_l0[3] ^ carry_in[3];
assign sum[4] = p_l0[4] ^ carry_in[4];
assign sum[5] = p_l0[5] ^ carry_in[5];
assign sum[6] = p_l0[6] ^ carry_in[6];
assign sum[7] = p_l0[7] ^ carry_in[7];

//------------------------------------------------------------------------------
// Assign carry out
//------------------------------------------------------------------------------
assign cout = carry_in[8];

endmodule