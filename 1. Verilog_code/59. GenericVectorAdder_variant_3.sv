//SystemVerilog
module vec_add #(parameter W=8)(
  input [W-1:0] vec1, vec2,
  output [W:0] vec_out
);

  // Conditional sum adder implementation
  wire [W-1:0] sum0, sum1;
  wire [W-1:0] carry0, carry1;
  
  // Precompute sums with carry=0 and carry=1
  assign sum0 = vec1 ^ vec2;
  assign sum1 = ~(vec1 ^ vec2);
  
  // Precompute carries
  assign carry0 = vec1 & vec2;
  assign carry1 = vec1 | vec2;
  
  // Select final sum based on carry chain
  reg [W-1:0] final_sum;
  reg final_carry;
  
  always @(*) begin
    final_sum[0] = sum0[0];
    final_carry = carry0[0];
    
    for (int i = 1; i < W; i++) begin
      if (final_carry) begin
        final_sum[i] = sum1[i];
        final_carry = carry1[i];
      end else begin
        final_sum[i] = sum0[i];
        final_carry = carry0[i];
      end
    end
  end
  
  assign vec_out[W-1:0] = final_sum;
  assign vec_out[W] = final_carry;

endmodule