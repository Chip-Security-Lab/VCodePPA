//SystemVerilog
module adder_8_ppa (
  input [7:0] a,
  input [7:0] b,
  output [7:0] sum
);

  wire [7:0] p;     // Propagate (a[i] ^ b[i])
  wire [7:0] g;     // Generate (a[i] & b[i])
  wire [8:0] C;     // Carries (C[0] = carry_in, C[i+1] = carry into bit i+1)

  // Generate and Propagate signals for each bit
  assign p = a ^ b;
  assign g = a & b;

  // Carry-in for the LSB (assumed 0 based on the original module interface)
  assign C[0] = 1'b0;

  // Ripple Carry Chain: C[i+1] is the carry generated at bit i, propagating to bit i+1
  // C[i+1] = g[i] | (p[i] & C[i])
  assign C[1] = g[0] | (p[0] & C[0]);
  assign C[2] = g[1] | (p[1] & C[1]);
  assign C[3] = g[2] | (p[2] & C[2]);
  assign C[4] = g[3] | (p[3] & C[3]);
  assign C[5] = g[4] | (p[4] & C[4]);
  assign C[6] = g[5] | (p[5] & C[5]);
  assign C[7] = g[6] | (p[6] & C[6]);
  assign C[8] = g[7] | (p[7] & C[7]); // Final carry-out (not part of the output sum)

  // Sum generation for each bit
  // sum[i] = p[i] ^ C[i] where C[i] is the carry into bit i
  assign sum = p ^ C[7:0];

endmodule