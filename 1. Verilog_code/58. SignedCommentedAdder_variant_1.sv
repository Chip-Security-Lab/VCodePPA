//SystemVerilog
module manchester_adder(
  input signed [7:0] operand_x,
  input signed [7:0] operand_y,
  output signed [8:0] sum_result
);

  // Generate and propagate signals
  wire [8:0] g, p;
  wire [8:0] c;
  
  // Generate and propagate computation
  assign g[0] = operand_x[0] & operand_y[0];
  assign p[0] = operand_x[0] ^ operand_y[0];
  
  genvar i;
  generate
    for(i=1; i<8; i=i+1) begin: gen_prop
      assign g[i] = operand_x[i] & operand_y[i];
      assign p[i] = operand_x[i] ^ operand_y[i];
    end
  endgenerate

  // Brent-Kung carry tree implementation
  wire [7:0] bk_carry;
  
  // First level
  assign bk_carry[0] = g[0];
  assign bk_carry[1] = g[1] | (p[1] & g[0]);
  assign bk_carry[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
  assign bk_carry[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
  
  // Second level
  wire [3:0] level2_carry;
  assign level2_carry[0] = bk_carry[0];
  assign level2_carry[1] = bk_carry[1];
  assign level2_carry[2] = bk_carry[2];
  assign level2_carry[3] = bk_carry[3];
  
  // Third level
  wire [1:0] level3_carry;
  assign level3_carry[0] = level2_carry[0];
  assign level3_carry[1] = level2_carry[1] | (p[3:2] & level2_carry[0]);
  
  // Fourth level
  wire level4_carry;
  assign level4_carry = level3_carry[0] | (p[7:4] & level3_carry[1]);
  
  // Final carry computation
  assign c[0] = bk_carry[0];
  assign c[1] = bk_carry[1];
  assign c[2] = bk_carry[2];
  assign c[3] = bk_carry[3];
  assign c[4] = level2_carry[0] | (p[4] & level3_carry[0]);
  assign c[5] = level2_carry[1] | (p[5] & level3_carry[0]);
  assign c[6] = level2_carry[2] | (p[6] & level3_carry[0]);
  assign c[7] = level2_carry[3] | (p[7] & level3_carry[0]);
  assign c[8] = level4_carry;
  
  // Sum computation
  assign sum_result[0] = p[0];
  assign sum_result[8:1] = p[7:0] ^ c[7:0];

endmodule