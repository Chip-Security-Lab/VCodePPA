//SystemVerilog
// SystemVerilog - Transformed Code
// Pipelined 4-bit Adder with Carry Lookahead
// Restructured data flow into a 3-stage pipeline

module add1_pipelined (
  input clk,     // Clock
  input rst_n,   // Asynchronous reset, active low
  input [3:0] x, // First operand
  input [3:0] y, // Second operand
  output [4:0] s // Sum (including carry out as MSB)
);

  //------------------------------------------------------------------------
  // Stage 1: Calculate Propagate (P') and Generate (G)
  // P' = x ^ y
  // G = x & y
  // Inputs: x, y
  // Outputs: p_prime_stage1, g_stage1 (registered results)
  //------------------------------------------------------------------------
  wire [3:0] p_prime_comb1; // Combinational P' calculation
  wire [3:0] g_comb1;       // Combinational G calculation

  reg [3:0] p_prime_stage1; // Registered P' for stage 2
  reg [3:0] g_stage1;       // Registered G for stage 2

  assign p_prime_comb1 = x ^ y;
  assign g_comb1 = x & y;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      p_prime_stage1 <= 4'b0;
      g_stage1 <= 4'b0;
    end else begin
      p_prime_stage1 <= p_prime_comb1;
      g_stage1 <= g_comb1;
    end
  end

  //------------------------------------------------------------------------
  // Stage 2: Calculate Carries (C) using Parallel Carry Lookahead
  // C[i+1] = G[i] | (P'[i] & C[i]) - implemented using expanded parallel form
  // Inputs: p_prime_stage1, g_stage1, Cin (fixed to 0)
  // Outputs: c_stage2 (registered carries), p_prime_stage2 (p_prime_stage1 passed through)
  //------------------------------------------------------------------------
  wire [4:0] c_comb2; // Combinational carries calculated in stage 2 (c_comb2[0] is Cin)

  reg [4:0] c_stage2;       // Registered carries for stage 3
  reg [3:0] p_prime_stage2; // Registered P' for stage 3 (passed from stage 1)

  // Cin for the adder is 0
  assign c_comb2[0] = 1'b0;

  // Expanded Parallel Carry Lookahead Logic based on p_prime_stage1 and g_stage1
  assign c_comb2[1] = g_stage1[0];
  assign c_comb2[2] = g_stage1[1] | (p_prime_stage1[1] & g_stage1[0]);
  assign c_comb2[3] = g_stage1[2] | (p_prime_stage1[2] & g_stage1[1]) | (p_prime_stage1[2] & p_prime_stage1[1] & g_stage1[0]);
  assign c_comb2[4] = g_stage1[3] | (p_prime_stage1[3] & g_stage1[2]) | (p_prime_stage1[3] & p_prime_stage1[2] & g_stage1[1]) | (p_prime_stage1[3] & p_prime_stage1[2] & p_prime_stage1[1] & g_stage1[0]);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      c_stage2 <= 5'b0;
      p_prime_stage2 <= 4'b0;
    end else begin
      c_stage2 <= c_comb2;
      p_prime_stage2 <= p_prime_stage1; // Pass P' to next stage
    end
  end

  //------------------------------------------------------------------------
  // Stage 3: Calculate Sum (S)
  // S[i] = P'[i] ^ C[i]
  // Inputs: p_prime_stage2, c_stage2
  // Outputs: s_stage3 (registered sum)
  //------------------------------------------------------------------------
  wire [4:0] s_comb3; // Combinational sum calculation in stage 3 (s_comb3[4] is Cout)

  reg [4:0] s_stage3; // Registered final sum

  // Sum bits based on p_prime_stage2 and c_stage2
  assign s_comb3[0] = p_prime_stage2[0] ^ c_stage2[0]; // c_stage2[0] is the Cin (0)
  assign s_comb3[1] = p_prime_stage2[1] ^ c_stage2[1];
  assign s_comb3[2] = p_prime_stage2[2] ^ c_stage2[2];
  assign s_comb3[3] = p_prime_stage2[3] ^ c_stage2[3];

  // The most significant bit of the sum is the final carry out
  assign s_comb3[4] = c_stage2[4];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_stage3 <= 5'b0;
    end else begin
      s_stage3 <= s_comb3;
    end
  end

  //------------------------------------------------------------------------
  // Output Assignment
  // The final sum is the output of the last pipeline stage
  //------------------------------------------------------------------------
  assign s = s_stage3;

endmodule