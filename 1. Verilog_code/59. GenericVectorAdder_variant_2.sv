//SystemVerilog
module vec_add #(parameter W=8)(
  input [W-1:0] vec1, vec2,
  output [W:0] vec_out
);

  // Han-Carlson adder implementation
  wire [W-1:0] g, p;
  wire [W-1:0] g_level1, p_level1;
  wire [W-1:0] g_level2, p_level2;
  wire [W-1:0] g_level3, p_level3;
  wire [W-1:0] carry;
  wire [W-1:0] sum;

  // Generate and propagate signals
  genvar i;
  generate
    for (i = 0; i < W; i = i + 1) begin : gen_prop
      assign g[i] = vec1[i] & vec2[i];
      assign p[i] = vec1[i] ^ vec2[i];
    end
  endgenerate

  // Level 1: 2-bit groups
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
  assign g_level1[5] = g[5] | (p[5] & g[4]);
  assign p_level1[5] = p[5] & p[4];
  assign g_level1[6] = g[6];
  assign p_level1[6] = p[6];
  assign g_level1[7] = g[7] | (p[7] & g[6]);
  assign p_level1[7] = p[7] & p[6];

  // Level 2: 4-bit groups
  assign g_level2[0] = g_level1[0];
  assign p_level2[0] = p_level1[0];
  assign g_level2[1] = g_level1[1];
  assign p_level2[1] = p_level1[1];
  assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
  assign p_level2[2] = p_level1[2] & p_level1[0];
  assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
  assign p_level2[3] = p_level1[3] & p_level1[1];
  assign g_level2[4] = g_level1[4];
  assign p_level2[4] = p_level1[4];
  assign g_level2[5] = g_level1[5];
  assign p_level2[5] = p_level1[5];
  assign g_level2[6] = g_level1[6] | (p_level1[6] & g_level1[4]);
  assign p_level2[6] = p_level1[6] & p_level1[4];
  assign g_level2[7] = g_level1[7] | (p_level1[7] & g_level1[5]);
  assign p_level2[7] = p_level1[7] & p_level1[5];

  // Level 3: 8-bit group
  assign g_level3[0] = g_level2[0];
  assign p_level3[0] = p_level2[0];
  assign g_level3[1] = g_level2[1];
  assign p_level3[1] = p_level2[1];
  assign g_level3[2] = g_level2[2];
  assign p_level3[2] = p_level2[2];
  assign g_level3[3] = g_level2[3];
  assign p_level3[3] = p_level2[3];
  assign g_level3[4] = g_level2[4] | (p_level2[4] & g_level2[0]);
  assign p_level3[4] = p_level2[4] & p_level2[0];
  assign g_level3[5] = g_level2[5] | (p_level2[5] & g_level2[1]);
  assign p_level3[5] = p_level2[5] & p_level2[1];
  assign g_level3[6] = g_level2[6] | (p_level2[6] & g_level2[2]);
  assign p_level3[6] = p_level2[6] & p_level2[2];
  assign g_level3[7] = g_level2[7] | (p_level2[7] & g_level2[3]);
  assign p_level3[7] = p_level2[7] & p_level2[3];

  // Generate carry signals
  assign carry[0] = 1'b0;
  assign carry[1] = g_level3[0];
  assign carry[2] = g_level3[1];
  assign carry[3] = g_level3[2];
  assign carry[4] = g_level3[3];
  assign carry[5] = g_level3[4];
  assign carry[6] = g_level3[5];
  assign carry[7] = g_level3[6];
  assign vec_out[W] = g_level3[7];

  // Generate sum
  generate
    for (i = 0; i < W; i = i + 1) begin : gen_sum
      assign sum[i] = p[i] ^ carry[i];
    end
  endgenerate

  assign vec_out[W-1:0] = sum;

endmodule