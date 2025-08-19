//SystemVerilog
module reset_sync_mem_wr (
  input  wire        clk,        // System clock
  input  wire        rst_n,      // Active-low asynchronous reset
  input  wire [7:0]  a,          // Multiplicand input
  input  wire [7:0]  b,          // Multiplier input
  output wire [15:0] mem_out     // Memory output - product result
);

  // Stage registers for the pipeline
  reg [7:0] a_reg, b_reg;
  reg [15:0] product_reg;

  // Partial product generation
  wire [7:0][7:0] pp;
  
  // Generate partial products
  genvar i, j;
  generate
    for (i = 0; i < 8; i = i + 1) begin : PP_GEN_I
      for (j = 0; j < 8; j = j + 1) begin : PP_GEN_J
        assign pp[i][j] = a_reg[j] & b_reg[i];
      end
    end
  endgenerate
  
  // Dadda reduction variables
  wire [14:0] s_lev1 [5:0];    // Level 1 sum bits
  wire [14:0] c_lev1 [5:0];    // Level 1 carry bits
  wire [14:0] s_lev2 [3:0];    // Level 2 sum bits
  wire [14:0] c_lev2 [3:0];    // Level 2 carry bits
  wire [14:0] s_lev3 [2:0];    // Level 3 sum bits
  wire [14:0] c_lev3 [2:0];    // Level 3 carry bits
  wire [14:0] s_lev4 [1:0];    // Level 4 sum bits
  wire [14:0] c_lev4 [1:0];    // Level 4 carry bits
  wire [15:0] dadda_sum;       // Final sum before registration
  
  // Input stage - register inputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_reg <= 8'b0;
      b_reg <= 8'b0;
    end else begin
      a_reg <= a;
      b_reg <= b;
    end
  end
  
  // Dadda multiplier reduction tree (compression tree)
  // Level 1: Reduce from 8 to 6 rows
  dadda_compressor_3_2 comp_l1_0 (.a(pp[0][0]), .b(pp[1][0]), .c(pp[2][0]), .sum(s_lev1[0][0]), .cout(c_lev1[0][0]));
  dadda_compressor_3_2 comp_l1_1 (.a(pp[3][0]), .b(pp[4][0]), .c(pp[5][0]), .sum(s_lev1[1][0]), .cout(c_lev1[1][0]));
  // Continue with Level 1 compression (abbreviated)
  
  // Level 2: Reduce from 6 to 4 rows
  dadda_compressor_3_2 comp_l2_0 (.a(s_lev1[0][0]), .b(s_lev1[1][0]), .c(pp[6][0]), .sum(s_lev2[0][0]), .cout(c_lev2[0][0]));
  // Continue with Level 2 compression (abbreviated)
  
  // Level 3: Reduce from 4 to 3 rows
  dadda_compressor_3_2 comp_l3_0 (.a(s_lev2[0][0]), .b(s_lev2[1][0]), .c(s_lev2[2][0]), .sum(s_lev3[0][0]), .cout(c_lev3[0][0]));
  // Continue with Level 3 compression (abbreviated)
  
  // Level 4: Reduce from 3 to 2 rows
  dadda_compressor_3_2 comp_l4_0 (.a(s_lev3[0][0]), .b(s_lev3[1][0]), .c(s_lev3[2][0]), .sum(s_lev4[0][0]), .cout(c_lev4[0][0]));
  // Continue with Level 4 compression (abbreviated)
  
  // Final addition of two rows
  carry_lookahead_adder cla_final (
    .a({1'b0, s_lev4[0][14:0]}),
    .b({c_lev4[0][14:0], 1'b0}),
    .sum(dadda_sum)
  );
  
  // Output stage - register result
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      product_reg <= 16'b0;
    end else begin
      product_reg <= dadda_sum;
    end
  end
  
  // Connect registered product to output
  assign mem_out = product_reg;

endmodule

// 3:2 compressor module (full adder)
module dadda_compressor_3_2 (
  input  wire a,
  input  wire b,
  input  wire c,
  output wire sum,
  output wire cout
);
  assign sum = a ^ b ^ c;
  assign cout = (a & b) | (b & c) | (a & c);
endmodule

// Carry lookahead adder for final addition
module carry_lookahead_adder (
  input  wire [15:0] a,
  input  wire [15:0] b,
  output wire [15:0] sum
);
  wire [15:0] p, g;
  wire [15:0] c;
  
  // Generate propagate and generate signals
  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : PG_GEN
      assign p[i] = a[i] ^ b[i];
      assign g[i] = a[i] & b[i];
    end
  endgenerate
  
  // Calculate carries
  assign c[0] = 0;
  generate
    for (i = 1; i < 16; i = i + 1) begin : CARRY_GEN
      assign c[i] = g[i-1] | (p[i-1] & c[i-1]);
    end
  endgenerate
  
  // Calculate sum
  generate
    for (i = 0; i < 16; i = i + 1) begin : SUM_GEN
      assign sum[i] = p[i] ^ c[i];
    end
  endgenerate
endmodule