//SystemVerilog
module reverse_add(
  input [0:3] vectorA,
  input [0:3] vectorB, 
  output [0:4] result
);

  // Generate and propagate signals
  wire [0:3] g = vectorA & vectorB;
  wire [0:3] p = vectorA ^ vectorB;

  // Carry computation using lookahead logic
  wire c1 = g[0];
  wire c2 = g[1] | (p[1] & g[0]);
  wire c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
  wire c4 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);

  // Sum computation
  assign result[0] = p[0];
  assign result[1] = p[1] ^ c1;
  assign result[2] = p[2] ^ c2;
  assign result[3] = p[3] ^ c3;
  assign result[4] = c4;

endmodule