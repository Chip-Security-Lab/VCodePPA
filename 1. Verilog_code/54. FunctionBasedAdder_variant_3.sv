//SystemVerilog
module func_adder(
  input [4:0] alpha, beta,
  output [5:0] sigma
);

  wire [4:0] g, p;
  wire [4:0] g_level1, p_level1;
  wire [4:0] g_level2, p_level2;
  wire [5:0] carry;
  
  // Generate and Propagate signals
  genvar i;
  generate
    for (i = 0; i < 5; i = i + 1) begin : gen_gp
      assign g[i] = alpha[i] & beta[i];
      assign p[i] = alpha[i] ^ beta[i];
    end
  endgenerate

  // First level prefix computation
  assign g_level1[0] = g[0];
  assign p_level1[0] = p[0];
  assign g_level1[1] = g[1] | (p[1] & g[0]);
  assign p_level1[1] = p[1] & p[0];
  assign g_level1[2] = g[2];
  assign p_level1[2] = p[2];
  assign g_level1[3] = g[3] | (p[3] & g[2]);
  assign p_level1[3] = p[3] & p[2];
  assign g_level1[4] = g[4];
  assign p_level1[4] = p[4];

  // Second level prefix computation
  assign g_level2[0] = g_level1[0];
  assign p_level2[0] = p_level1[0];
  assign g_level2[1] = g_level1[1];
  assign p_level2[1] = p_level1[1];
  assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[1]);
  assign p_level2[2] = p_level1[2] & p_level1[1];
  assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
  assign p_level2[3] = p_level1[3] & p_level1[1];
  assign g_level2[4] = g_level1[4] | (p_level1[4] & g_level1[3]);
  assign p_level2[4] = p_level1[4] & p_level1[3];

  // Carry computation
  assign carry[0] = 1'b0;
  assign carry[1] = g_level2[0];
  assign carry[2] = g_level2[1];
  assign carry[3] = g_level2[2];
  assign carry[4] = g_level2[3];
  assign carry[5] = g_level2[4];

  // Sum computation
  assign sigma[0] = p[0];
  assign sigma[1] = p[1] ^ carry[1];
  assign sigma[2] = p[2] ^ carry[2];
  assign sigma[3] = p[3] ^ carry[3];
  assign sigma[4] = p[4] ^ carry[4];
  assign sigma[5] = carry[5];

endmodule