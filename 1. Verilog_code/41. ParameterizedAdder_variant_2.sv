//SystemVerilog
// SystemVerilog
module adder_8_pipelined (
  input wire clk,
  input wire rst,
  input wire [7:0] a,
  input wire [7:0] b,
  output wire [7:0] sum
);

  // Stage 0: Combinational logic (Compute G/P and lower carries)
  wire [7:0] s0_gen;
  wire [7:0] s0_prop;
  wire [4:0] s0_carry_low; // carry_signals[0] to carry_signals[4]

  assign s0_gen = a & b;
  assign s0_prop = a ^ b;

  // Input carry (assuming 0 for a simple adder)
  assign s0_carry_low[0] = 1'b0;

  // Calculate carry chain for lower 4 bits (bits 0-3)
  assign s0_carry_low[1] = s0_gen[0] | (s0_prop[0] & s0_carry_low[0]);
  assign s0_carry_low[2] = s0_gen[1] | (s0_prop[1] & s0_carry_low[1]);
  assign s0_carry_low[3] = s0_gen[2] | (s0_prop[2] & s0_carry_low[2]);
  assign s0_carry_low[4] = s0_gen[3] | (s0_prop[3] & s0_carry_low[3]); // Carry out of lower 4 bits

  // Stage 1: Register Stage 0 outputs
  reg [7:0] s1_gen_reg;
  reg [7:0] s1_prop_reg;
  reg [4:0] s1_carry_low_reg;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      s1_gen_reg <= 8'b0;
      s1_prop_reg <= 8'b0;
      s1_carry_low_reg <= 5'b0;
    end else begin
      s1_gen_reg <= s0_gen;
      s1_prop_reg <= s0_prop;
      s1_carry_low_reg <= s0_carry_low;
    end
  end

  // Stage 2: Combinational logic (Compute upper carries and final sum)
  wire [8:0] s2_carry; // Full carry chain signals (c0 to c8)
  wire [7:0] s2_sum;

  // Use registered lower carries from Stage 1
  assign s2_carry[0] = s1_carry_low_reg[0];
  assign s2_carry[1] = s1_carry_low_reg[1];
  assign s2_carry[2] = s1_carry_low_reg[2];
  assign s2_carry[3] = s1_carry_low_reg[3];
  assign s2_carry[4] = s1_carry_low_reg[4]; // Registered carry from lower half (bit 3)

  // Calculate carry chain for upper 4 bits (bits 4-7) using registered signals
  assign s2_carry[5] = s1_gen_reg[4] | (s1_prop_reg[4] & s2_carry[4]);
  assign s2_carry[6] = s1_gen_reg[5] | (s1_prop_reg[5] & s2_carry[5]);
  assign s2_carry[7] = s1_gen_reg[6] | (s1_prop_reg[6] & s2_carry[7]);
  assign s2_carry[8] = s1_gen_reg[7] | (s1_prop_reg[7] & s2_carry[8]); // Final carry out (c8)

  // Calculate sum bits using registered propagate and calculated carries
  assign s2_sum[0] = s1_prop_reg[0] ^ s2_carry[0];
  assign s2_sum[1] = s1_prop_reg[1] ^ s2_carry[1];
  assign s2_sum[2] = s1_prop_reg[2] ^ s2_carry[2];
  assign s2_sum[3] = s1_prop_reg[3] ^ s2_carry[3];
  assign s2_sum[4] = s1_prop_reg[4] ^ s2_carry[4];
  assign s2_sum[5] = s1_prop_reg[5] ^ s2_carry[5];
  assign s2_sum[6] = s1_prop_reg[6] ^ s2_carry[6];
  assign s2_sum[7] = s1_prop_reg[7] ^ s2_carry[7];

  // Stage 3: Register Stage 2 output (Final sum)
  reg [7:0] s3_sum_reg;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      s3_sum_reg <= 8'b0;
    end else begin
      s3_sum_reg <= s2_sum;
    end
  end

  // Output Assignment
  assign sum = s3_sum_reg;

endmodule