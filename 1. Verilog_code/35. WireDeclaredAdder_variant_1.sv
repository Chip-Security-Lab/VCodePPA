//SystemVerilog
module pipelined_adder_8bit (
  input wire        clk,
  input wire        rst_n, // Active low reset
  input wire [7:0]  a,
  input wire [7:0]  b,
  input wire        cin,
  output logic [7:0] sum,
  output logic       cout
);

  // Stage 1: Calculate P and G, Register inputs
  // Combinational logic for Stage 1
  logic [7:0] p_s1_comb;
  logic [7:0] g_s1_comb;

  assign p_s1_comb = a ^ b;
  assign g_s1_comb = a & b;

  // Registers for Stage 1 outputs (inputs to Stage 2)
  logic [7:0] p_s1_reg;
  logic [7:0] g_s1_reg;
  logic       cin_s1_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      p_s1_reg <= '0;
      g_s1_reg <= '0;
      cin_s1_reg <= '0;
    end else begin
      p_s1_reg <= p_s1_comb;
      g_s1_reg <= g_s1_comb;
      cin_s1_reg <= cin;
    end
  end

  // Stage 2: Calculate Carries, Sum, and Cout
  // Combinational logic for Stage 2
  logic [8:0] carries_s2_comb; // C[0] to C[8]
  logic [7:0] sum_s2_comb;
  logic       cout_s2_comb;

  // Calculate carries based on registered P, G, and cin
  assign carries_s2_comb[0] = cin_s1_reg;
  // Block 0 (bits 0-3) carries
  assign carries_s2_comb[1] = g_s1_reg[0] | (p_s1_reg[0] & carries_s2_comb[0]);
  assign carries_s2_comb[2] = g_s1_reg[1] | (p_s1_reg[1] & carries_s2_comb[1]);
  assign carries_s2_comb[3] = g_s1_reg[2] | (p_s1_reg[2] & carries_s2_comb[2]);

  // Block 0 Group P and G
  logic gp0_s2_comb;
  logic gg0_s2_comb;
  assign gp0_s2_comb = p_s1_reg[3] & p_s1_reg[2] & p_s1_reg[1] & p_s1_reg[0];
  assign gg0_s2_comb = g_s1_reg[3] | (p_s1_reg[3] & g_s1_reg[2]) | (p_s1_reg[3] & p_s1_reg[2] & g_s1_reg[1]) | (p_s1_reg[3] & p_s1_reg[2] & p_s1_reg[1] & g_s1_reg[0]);

  // Carry out of Block 0
  assign carries_s2_comb[4] = gg0_s2_comb | (gp0_s2_comb & carries_s2_comb[0]);

  // Block 1 (bits 4-7) carries
  assign carries_s2_comb[5] = g_s1_reg[4] | (p_s1_reg[4] & carries_s2_comb[4]);
  assign carries_s2_comb[6] = g_s1_reg[5] | (p_s1_reg[5] & carries_s2_comb[5]);
  assign carries_s2_comb[7] = g_s1_reg[6] | (p_s1_reg[6] & carries_s2_comb[6]);

  // Block 1 Group P and G
  logic gp1_s2_comb;
  logic gg1_s2_comb;
  assign gp1_s2_comb = p_s1_reg[7] & p_s1_reg[6] & p_s1_reg[5] & p_s1_reg[4];
  assign gg1_s2_comb = g_s1_reg[7] | (p_s1_reg[7] & g_s1_reg[6]) | (p_s1_reg[7] & p_s1_reg[6] & g_s1_reg[5]) | (p_s1_reg[7] & p_s1_reg[6] & p_s1_reg[5] & g_s1_reg[4]);

  // Carry out of Block 1 (final cout)
  assign carries_s2_comb[8] = gg1_s2_comb | (gp1_s2_comb & carries_s2_comb[4]);

  // Calculate sum bits
  assign sum_s2_comb = p_s1_reg ^ carries_s2_comb[7:0];

  // Assign final cout
  assign cout_s2_comb = carries_s2_comb[8];

  // Stage 2 Registers (Output Registers)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum <= '0;
      cout <= '0;
    end else begin
      sum <= sum_s2_comb;
      cout <= cout_s2_comb;
    end
  end

endmodule