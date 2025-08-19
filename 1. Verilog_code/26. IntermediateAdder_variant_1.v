module Adder_4(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

wire [3:0] p; // Propagate signals
wire [3:0] g; // Generate signals

// Calculate initial P and G for each bit
assign p = A ^ B;
assign g = A & B;

// Calculate carries using parallel logic (Carry Lookahead structure)
// c_out_i is the carry out of bit i (carry into bit i+1)
wire c_out_0; // Carry out of bit 0 (carry into bit 1)
wire c_out_1; // Carry out of bit 1 (carry into bit 2)
wire c_out_2; // Carry out of bit 2 (carry into bit 3)
wire c_out_3; // Carry out of bit 3 (final carry out)

// Parallel carry generation using expanded boolean expressions
// Assuming carry-in to bit 0 is 0
assign c_out_0 = g[0];
assign c_out_1 = g[1] | (p[1] & g[0]);
assign c_out_2 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
assign c_out_3 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);

// Calculate sum bits
wire [4:0] s;
// s[i] = p[i] ^ carry_in_i
// carry_in_0 = 0
// carry_in_1 = c_out_0
// carry_in_2 = c_out_1
// carry_in_3 = c_out_2
// carry_out_4 = c_out_3

assign s[0] = p[0]; // s[0] = p[0] ^ carry_in_0 = p[0] ^ 0 = p[0]
assign s[1] = p[1] ^ c_out_0;
assign s[2] = p[2] ^ c_out_1;
assign s[3] = p[3] ^ c_out_2;
assign s[4] = c_out_3; // The carry-out is the most significant bit of the sum

assign sum = s;

endmodule