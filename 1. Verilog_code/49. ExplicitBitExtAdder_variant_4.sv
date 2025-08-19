//SystemVerilog
// Pipelined Bitwise Adder (3-bit input, 4-bit output)
// Implements a 3-stage pipeline based on a 4-bit Carry Lookahead Adder structure
// Stage 1: Input registration, Extend, G/P calculation
// Stage 2: Carry calculation (Optimized/Expanded CLA form)
// Stage 3: Sum calculation, Output registration

module bitwise_add_pipelined (
  input wire clk,      // Clock
  input wire rst_n,    // Asynchronous active-low reset
  input wire [2:0] a,  // First operand (3 bits)
  input wire [2:0] b,  // Second operand (3 bits)
  output wire [3:0] total // Sum (4 bits)
);

  //----------------------------------------------------------------------------
  // Stage 1: Input registration, Extend, G/P calculation
  // Registers inputs and calculates initial G/P signals
  //----------------------------------------------------------------------------

  // Registered inputs
  reg [2:0] a_s1_reg;
  reg [2:0] b_s1_reg;

  // Combinational logic within Stage 1
  // Extend inputs for 4-bit CLA structure (carry-in is implicit 0)
  wire [3:0] a_ext_s1 = {1'b0, a_s1_reg};
  wire [3:0] b_ext_s1 = {1'b0, b_s1_reg};

  // Calculate Generate (G) and Propagate (P) signals for each bit position
  wire [3:0] g_s1 = a_ext_s1 & b_ext_s1; // G[i] = A[i] & B[i]
  wire [3:0] p_s1 = a_ext_s1 | b_ext_s1; // P[i] = A[i] | B[i]

  // Registers for Stage 1 outputs (inputs for Stage 2)
  // These signals are passed to the next stage for carry calculation
  reg [3:0] g_s2_reg;     // Registered G signals for Stage 2
  reg [3:0] p_s2_reg;     // Registered P signals for Stage 2
  // Extended inputs also need to be passed to Stage 3 for sum calculation
  reg [3:0] a_ext_s2_reg; // Registered extended a for Stage 3
  reg [3:0] b_ext_s2_reg; // Registered extended b for Stage 3

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_s1_reg     <= '0;
      b_s1_reg     <= '0;
      g_s2_reg     <= '0;
      p_s2_reg     <= '0;
      a_ext_s2_reg <= '0;
      b_ext_s2_reg <= '0;
    end else begin
      a_s1_reg     <= a;          // Register input a
      b_s1_reg     <= b;          // Register input b
      g_s2_reg     <= g_s1;       // Pass G to next stage
      p_s2_reg     <= p_s1;       // Pass P to next stage
      a_ext_s2_reg <= a_ext_s1;   // Pass extended A to Stage 3
      b_ext_s2_reg <= b_ext_s1;   // Pass extended B to Stage 3
    end
  end

  //----------------------------------------------------------------------------
  // Stage 2: Carry calculation (Carry Lookahead - Expanded Form)
  // Calculates carries based on G/P signals from Stage 1
  //----------------------------------------------------------------------------

  // Combinational logic within Stage 2
  // Uses registered G and P from Stage 1 (g_s2_reg, p_s2_reg)
  // Carry signals c_s2[i] represent C(i+1)
  wire [3:0] c_s2; // Carries C1, C2, C3, C4 (c_s2[0]=C1, c_s2[1]=C2, c_s2[2]=C3, c_s2[3]=C4)
                   // C0 is implicitly 0.

  // Calculate carries using the expanded Carry Lookahead principle: C(i+1) = G[i] | (P[i] & C[i])
  // C1 = G0 | (P0 & C0) = G0 (C0 is 0)
  assign c_s2[0] = g_s2_reg[0];
  // C2 = G1 | P1 & C1 = G1 | P1 & G0
  assign c_s2[1] = g_s2_reg[1] | (p_s2_reg[1] & g_s2_reg[0]);
  // C3 = G2 | P2 & C2 = G2 | P2 & (G1 | P1 & G0) = G2 | P2&G1 | P2&P1&G0
  assign c_s2[2] = g_s2_reg[2] | (p_s2_reg[2] & g_s2_reg[1]) | (p_s2_reg[2] & p_s2_reg[1] & g_s2_reg[0]);
  // C4 = G3 | P3 & C3 = G3 | P3 & (G2 | P2&G1 | P2&P1&G0) = G3 | P3&G2 | P3&P2&G1 | P3&P2&P1&G0
  assign c_s2[3] = g_s2_reg[3] | (p_s2_reg[3] & g_s2_reg[2]) | (p_s2_reg[3] & p_s2_reg[2] & g_s2_reg[1]) | (p_s2_reg[3] & p_s2_reg[2] & p_s2_reg[1] & g_s2_reg[0]);


  // Register for Stage 2 outputs (inputs for Stage 3)
  // Registered carries are passed to the next stage for sum calculation
  reg [3:0] c_s3_reg; // Registered carries for Stage 3 (c_s3_reg[0]=C1, c_s3_reg[1]=C2, etc.)

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      c_s3_reg <= '0;
    end else begin
      c_s3_reg <= c_s2; // Register carries from Stage 2
    end
  end

  //----------------------------------------------------------------------------
  // Stage 3: Sum calculation, Output registration
  // Calculates sum bits and registers the final result
  //----------------------------------------------------------------------------

  // Combinational logic within Stage 3
  // Uses registered extended inputs from Stage 1 (a_ext_s2_reg, b_ext_s2_reg)
  // and registered carries from Stage 2 (c_s3_reg)
  wire [3:0] s_s3; // Sum bits

  // Calculate sum bits S[i] = A[i] ^ B[i] ^ C[i]
  // S0 = A0 ^ B0 ^ C0 = A0 ^ B0 (C0 is 0)
  assign s_s3[0] = a_ext_s2_reg[0] ^ b_ext_s2_reg[0];
  // S1 = A1 ^ B1 ^ C1
  assign s_s3[1] = a_ext_s2_reg[1] ^ b_ext_s2_reg[1] ^ c_s3_reg[0]; // Uses C1 (c_s3_reg[0])
  // S2 = A2 ^ B2 ^ C2
  assign s_s3[2] = a_ext_s2_reg[2] ^ b_ext_s2_reg[2] ^ c_s3_reg[1]; // Uses C2 (c_s3_reg[1])
  // S3 = A3 ^ B3 ^ C3
  assign s_s3[3] = a_ext_s2_reg[3] ^ b_ext_s2_reg[3] ^ c_s3_reg[2]; // Uses C3 (c_s3_reg[2])

  // Register for Stage 3 output (final output)
  reg [3:0] total_reg; // Registered final sum

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      total_reg <= '0;
    end else begin
      total_reg <= s_s3; // Register final sum from Stage 3
    end
  end

  //----------------------------------------------------------------------------
  // Output Assignment
  // Assign the final registered sum to the output port
  //----------------------------------------------------------------------------

  assign total = total_reg;

endmodule