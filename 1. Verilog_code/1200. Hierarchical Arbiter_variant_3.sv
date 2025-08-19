//SystemVerilog
module hierarchical_arbiter(
  input clk, rst_n,
  input [7:0] requests,
  output reg [7:0] grants
);
  reg [1:0] group_reqs;
  reg [1:0] group_grants;
  reg [3:0] sub_grants [0:1];
  
  // Signals for Karatsuba multiplier
  reg [7:0] mult_a, mult_b;
  wire [15:0] mult_result;
  
  // Always block for arbiter logic
  always @(*) begin
    // Simplified request group detection
    group_reqs[0] = requests[0] | requests[1] | requests[2] | requests[3];
    group_reqs[1] = requests[4] | requests[5] | requests[6] | requests[7];
  
    // Top-level arbiter - simplified priority logic
    group_grants[0] = group_reqs[0] & ~group_reqs[1];
    group_grants[1] = group_reqs[1];
  
    // Clear sub-grants first
    sub_grants[0] = 4'b0000;
    sub_grants[1] = 4'b0000;
    
    // Optimized first sub-arbiter using priority encoding
    if (group_grants[0]) begin
      sub_grants[0][0] = requests[0];
      sub_grants[0][1] = ~requests[0] & requests[1];
      sub_grants[0][2] = ~requests[0] & ~requests[1] & requests[2];
      sub_grants[0][3] = ~requests[0] & ~requests[1] & ~requests[2] & requests[3];
    end
    
    // Optimized second sub-arbiter using priority encoding
    if (group_grants[1]) begin
      sub_grants[1][0] = requests[4];
      sub_grants[1][1] = ~requests[4] & requests[5];
      sub_grants[1][2] = ~requests[4] & ~requests[5] & requests[6];
      sub_grants[1][3] = ~requests[4] & ~requests[5] & ~requests[6] & requests[7];
    end
    
    // Simplified multiplier inputs
    mult_a = {4'b0, sub_grants[0]};
    mult_b = {4'b0, sub_grants[1]};
  end
  
  // Sequential logic with multiplication result usage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      grants <= 8'h00;
    else
      // The XOR with (mult_result[7:0] & 8'h00) is always 0, so removed
      grants <= {sub_grants[1], sub_grants[0]};
  end
  
  // Instantiate recursive Karatsuba multiplier
  karatsuba_mult_8bit karatsuba_inst (
    .a(mult_a),
    .b(mult_b),
    .result(mult_result)
  );
endmodule

// Recursive Karatsuba multiplier module (8-bit)
module karatsuba_mult_8bit(
  input [7:0] a,
  input [7:0] b,
  output [15:0] result
);
  wire [15:0] direct_mult;
  wire [3:0] a_high, a_low, b_high, b_low;
  wire [15:0] p1, p2, p3;
  wire [15:0] temp;
  
  assign a_high = a[7:4];
  assign a_low = a[3:0];
  assign b_high = b[7:4];
  assign b_low = b[3:0];
  
  // Recursive implementation via smaller Karatsuba modules
  karatsuba_mult_4bit high_mult (
    .a(a_high),
    .b(b_high),
    .result(p1)
  );
  
  karatsuba_mult_4bit low_mult (
    .a(a_low),
    .b(b_low),
    .result(p2)
  );
  
  // Optimized XOR operations
  wire [3:0] a_sum = a_high ^ a_low;
  wire [3:0] b_sum = b_high ^ b_low;
  
  karatsuba_mult_4bit mid_mult (
    .a(a_sum),
    .b(b_sum),
    .result(temp)
  );
  
  assign p3 = temp ^ p1 ^ p2;
  
  // Optimized Karatsuba formula
  wire [15:0] high_shifted = {p1, 8'b0};
  wire [15:0] mid_shifted = {p3, 4'b0};
  assign result = high_shifted + mid_shifted + p2;
endmodule

// 4-bit Karatsuba multiplier module
module karatsuba_mult_4bit(
  input [3:0] a,
  input [3:0] b,
  output [7:0] result
);
  wire [1:0] a_high, a_low, b_high, b_low;
  wire [3:0] p1, p2, p3;
  
  assign a_high = a[3:2];
  assign a_low = a[1:0];
  assign b_high = b[3:2];
  assign b_low = b[1:0];
  
  // For 2-bit multiplications, use direct multiplication
  assign p1 = a_high * b_high;
  assign p2 = a_low * b_low;
  
  // Simplified XOR operation
  wire [1:0] a_sum = a_high ^ a_low;
  wire [1:0] b_sum = b_high ^ b_low;
  assign p3 = a_sum * b_sum;
  
  // Optimized Karatsuba formula calculation
  wire [3:0] middle_term = p3 ^ p1 ^ p2;
  assign result = {p1, 4'b0} + {middle_term, 2'b0} + p2;
endmodule