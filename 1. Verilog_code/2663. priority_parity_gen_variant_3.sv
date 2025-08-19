//SystemVerilog
module priority_parity_gen(
  input [15:0] data,
  input [3:0] priority_level,
  output parity_result
);
  // Internal signals
  wire [15:0] masked_data;
  wire [15:0] carry_chain;
  wire [15:0] gen, prop;
  
  // Skip carry adder logic for priority masking
  // Generate and propagate signals
  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin: gen_mask
      // Only bits >= priority_level will pass through
      assign gen[i] = (i >= priority_level) ? data[i] : 1'b0;
      assign prop[i] = (i >= priority_level) ? 1'b1 : 1'b0;
    end
  endgenerate
  
  // Skip carry chain implementation
  // Group size of 4 for the skip-carry structure
  assign carry_chain[0] = gen[0];
  
  // First group (0-3)
  assign carry_chain[1] = gen[1] | (prop[1] & carry_chain[0]);
  assign carry_chain[2] = gen[2] | (prop[2] & carry_chain[1]);
  assign carry_chain[3] = gen[3] | (prop[3] & carry_chain[2]);
  
  // Second group (4-7)
  wire group1_prop = prop[3] & prop[2] & prop[1] & prop[0];
  assign carry_chain[4] = gen[4] | (prop[4] & (group1_prop ? carry_chain[0] : carry_chain[3]));
  assign carry_chain[5] = gen[5] | (prop[5] & carry_chain[4]);
  assign carry_chain[6] = gen[6] | (prop[6] & carry_chain[5]);
  assign carry_chain[7] = gen[7] | (prop[7] & carry_chain[6]);
  
  // Third group (8-11)
  wire group2_prop = prop[7] & prop[6] & prop[5] & prop[4];
  assign carry_chain[8] = gen[8] | (prop[8] & (group2_prop ? carry_chain[4] : carry_chain[7]));
  assign carry_chain[9] = gen[9] | (prop[9] & carry_chain[8]);
  assign carry_chain[10] = gen[10] | (prop[10] & carry_chain[9]);
  assign carry_chain[11] = gen[11] | (prop[11] & carry_chain[10]);
  
  // Fourth group (12-15)
  wire group3_prop = prop[11] & prop[10] & prop[9] & prop[8];
  assign carry_chain[12] = gen[12] | (prop[12] & (group3_prop ? carry_chain[8] : carry_chain[11]));
  assign carry_chain[13] = gen[13] | (prop[13] & carry_chain[12]);
  assign carry_chain[14] = gen[14] | (prop[14] & carry_chain[13]);
  assign carry_chain[15] = gen[15] | (prop[15] & carry_chain[14]);
  
  // Generate masked data using the carry chain
  assign masked_data = {16{1'b0}} | (data & {16{1'b1}} & carry_chain);
  
  // Final parity calculation
  assign parity_result = ^masked_data;
endmodule