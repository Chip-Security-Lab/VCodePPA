//SystemVerilog
module multi_assign(
  input [3:0] val1, val2,
  output [4:0] sum,
  output carry
);

  wire [3:0] g, p;
  wire [4:0] c;
  
  // Generate and propagate signals
  assign g = val1 & val2;
  assign p = val1 ^ val2;
  
  // Carry lookahead logic
  wire [3:0] g_group, p_group;
  
  // First level carry lookahead
  assign g_group[0] = g[0];
  assign p_group[0] = p[0];
  assign g_group[1] = g[1] | (p[1] & g[0]);
  assign p_group[1] = p[1] & p[0];
  assign g_group[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
  assign p_group[2] = p[2] & p[1] & p[0];
  assign g_group[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
  assign p_group[3] = p[3] & p[2] & p[1] & p[0];
  
  // Carry chain
  assign c[0] = 1'b0;
  assign c[1] = g_group[0];
  assign c[2] = g_group[1];
  assign c[3] = g_group[2];
  assign c[4] = g_group[3];
  
  // Sum calculation
  assign sum[3:0] = p ^ c[3:0];
  assign sum[4] = c[4];
  assign carry = c[4];
  
endmodule