//SystemVerilog
module manchester_adder_8bit (
    input [7:0] a,
    input [7:0] b,
    input       c_in,
    output [7:0] sum,
    output      c_out
);

wire [7:0] P; // Propagate signals
wire [7:0] G; // Generate signals
wire [8:0] C; // Carries, C[0] is c_in

// Generate P and G for each bit
assign P = a ^ b;
assign G = a & b;

// Carry chain (Manchester principle implementation)
assign C[0] = c_in;
assign C[1] = G[0] | (P[0] & C[0]);
assign C[2] = G[1] | (P[1] & C[1]);
assign C[3] = G[2] | (P[2] & C[2]);
assign C[4] = G[3] | (P[3] & C[3]);
assign C[5] = G[4] | (P[4] & C[4]);
assign C[6] = G[5] | (P[5] & C[5]);
assign C[7] = G[6] | (P[6] & C[6]);
assign C[8] = G[7] | (P[7] & C[7]);

// Sum calculation
assign sum = P ^ C[7:0]; // sum[i] = P[i] ^ C[i]

// Output carry
assign c_out = C[8];

endmodule