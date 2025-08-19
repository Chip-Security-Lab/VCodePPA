//SystemVerilog
module alias_add(
  input [5:0] primary, secondary,
  output [6:0] aggregate
);

  wire [5:0] operand_A = primary;
  wire [5:0] operand_B = secondary;
  
  // Brent-Kung adder implementation
  wire [5:0] g, p;
  wire [5:0] g_level1, p_level1;
  wire [2:0] g_level2, p_level2;
  wire [0:0] g_level3, p_level3;
  
  // Generate and propagate signals
  genvar i;
  generate
    for (i = 0; i < 6; i = i + 1) begin : gen_gp
      assign g[i] = operand_A[i] & operand_B[i];
      assign p[i] = operand_A[i] ^ operand_B[i];
    end
  endgenerate
  
  // First level of prefix computation
  assign g_level1[0] = g[0];
  assign p_level1[0] = p[0];
  generate
    for (i = 1; i < 6; i = i + 1) begin : level1
      assign g_level1[i] = g[i] | (p[i] & g[i-1]);
      assign p_level1[i] = p[i] & p[i-1];
    end
  endgenerate
  
  // Second level of prefix computation
  assign g_level2[0] = g_level1[1];
  assign p_level2[0] = p_level1[1];
  generate
    for (i = 2; i < 6; i = i + 2) begin : level2
      assign g_level2[i/2] = g_level1[i] | (p_level1[i] & g_level1[i-1]);
      assign p_level2[i/2] = p_level1[i] & p_level1[i-1];
    end
  endgenerate
  
  // Third level of prefix computation
  assign g_level3[0] = g_level2[1] | (p_level2[1] & g_level2[0]);
  assign p_level3[0] = p_level2[1] & p_level2[0];
  
  // Sum computation
  wire [5:0] carry;
  assign carry[0] = 1'b0;
  assign carry[1] = g_level1[0];
  assign carry[2] = g_level1[1];
  assign carry[3] = g_level2[0];
  assign carry[4] = g_level1[3];
  assign carry[5] = g_level2[1];
  
  // Final sum
  assign aggregate[0] = p[0];
  generate
    for (i = 1; i < 6; i = i + 1) begin : sum
      assign aggregate[i] = p[i] ^ carry[i-1];
    end
  endgenerate
  assign aggregate[6] = g_level3[0];
  
endmodule