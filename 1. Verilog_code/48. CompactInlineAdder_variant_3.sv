//SystemVerilog
module add1(input [3:0]x,y, output [4:0]s);

  // 1. Pre-processing: Generate propagate (p) and generate (g) signals
  wire [3:0] p; // Propagate: p[i] = x[i] ^ y[i]
  wire [3:0] g; // Generate: g[i] = x[i] & y[i]

  assign p = x ^ y;
  assign g = x & y;

  // 2. Generate carries using simplified Boolean expressions (flattened carry-lookahead)
  // c[i] is the carry *into* bit i. c[0] is assumed 0.
  wire [4:1] c;

  // c[1] = g[0]
  assign c[1] = g[0];

  // c[2] = g[1] | (p[1] & g[0])
  assign c[2] = g[1] | (p[1] & g[0]);

  // c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0])
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);

  // c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0])
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);


  // 3. Sum Generation
  // s[i] = p[i] ^ c[i] (with c[0]=0)
  // s[4] = c[4] (carry out)

  assign s[0] = p[0]; // s[0] = p[0] ^ c[0], where c[0] = 0
  assign s[1] = p[1] ^ c[1];
  assign s[2] = p[2] ^ c[2];
  assign s[3] = p[3] ^ c[3];
  assign s[4] = c[4]; // Carry out is c[4]

endmodule