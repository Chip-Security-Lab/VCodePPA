//SystemVerilog
module proc_adder (
  input wire clk,
  input wire rst_n, // Active low reset
  input wire [5:0] p,
  input wire [5:0] q,
  output reg [6:0] result
);

  // Internal wire to hold the combinatorial sum result
  wire [6:0] sum_combinatorial;

  // Brent-Kung Adder Implementation (6-bit inputs, 7-bit output)

  // Level 0: Pre-processing (Generate and Propagate)
  wire [5:0] g_lp; // Local Generate
  wire [5:0] p_lp; // Local Propagate

  assign g_lp = p & q;
  assign p_lp = p ^ q;

  // Level 1: Group Propagate and Generate (step = 1)
  // (G_1:0, P_1:0) = (g_1, p_1) o (g_0, p_0)
  wire G10, P10;
  assign G10 = g_lp[1] | (p_lp[1] & g_lp[0]);
  assign P10 = p_lp[1] & p_lp[0];

  // (G_3:2, P_3:2) = (g_3, p_3) o (g_2, p_2)
  wire G32, P32;
  assign G32 = g_lp[3] | (p_lp[3] & g_lp[2]);
  assign P32 = p_lp[3] & p_lp[2];

  // (G_5:4, P_5:4) = (g_5, p_5) o (g_4, p_4)
  wire G54, P54;
  assign G54 = g_lp[5] | (p_lp[5] & g_lp[4]);
  assign P54 = p_lp[5] & p_lp[4];

  // Level 2: Group Propagate and Generate (step = 2)
  // (G_3:0, P_3:0) = (G_3:2, P_3:2) o (G_1:0, P_1:0)
  wire G30, P30;
  assign G30 = G32 | (P32 & G10);
  assign P30 = P32 & P10;

  // (G_5:2, P_5:2) = (G_5:4, P_5:4) o (G_3:2, P_3:2)
  wire G52, P52;
  assign G52 = G54 | (P54 & G32);
  assign P52 = P54 & P32;

  // Level 3: Group Propagate and Generate (step = 4)
  // (G_5:0, P_5:0) = (G_5:2, P_5:2) o (G_3:0, P_3:0)
  wire G50, P50; // P50 is not strictly needed for carries but calculated
  assign G50 = G52 | (P52 & G30);
  assign P50 = P52 & P30;

  // Backward Pass: Calculate intermediate carries using gray cells
  // G_2:0 = (G_1:0, P_1:0) o (g_2, p_2)
  wire G20; // G_2:0
  assign G20 = G10 | (P10 & g_lp[2]);

  // G_4:0 = (G_3:0, P_3:0) o (g_4, p_4)
  wire G40; // G_4:0
  assign G40 = G30 | (P30 & g_lp[4]);

  // Carries (c_i = G_{i-1}:0, with c_0 = 0)
  wire [6:0] carries;
  assign carries[0] = 1'b0;      // External carry-in is 0
  assign carries[1] = g_lp[0];   // c1 = G_0:0
  assign carries[2] = G10;       // c2 = G_1:0
  assign carries[3] = G20;       // c3 = G_2:0
  assign carries[4] = G30;       // c4 = G_3:0
  assign carries[5] = G40;       // c5 = G_4:0
  assign carries[6] = G50;       // c6 = G_5:0 (Carry-out)

  // Sum bits (s_i = p_i ^ c_i)
  wire [5:0] sum_bits;
  assign sum_bits[0] = p_lp[0] ^ carries[0]; // s0 = p0 ^ 0
  assign sum_bits[1] = p_lp[1] ^ carries[1]; // s1 = p1 ^ c1
  assign sum_bits[2] = p_lp[2] ^ carries[2]; // s2 = p2 ^ c2
  assign sum_bits[3] = p_lp[3] ^ carries[3]; // s3 = p3 ^ c3
  assign sum_bits[4] = p_lp[4] ^ carries[4]; // s4 = p4 ^ c4
  assign sum_bits[5] = p_lp[5] ^ carries[5]; // s5 = p5 ^ c5

  // Combine carry out and sum bits
  assign sum_combinatorial = {carries[6], sum_bits};

  // Sequential logic to register the sum
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset the output register to 0
      result <= 7'b0;
    end else begin
      // On the positive clock edge, capture the combinatorial sum
      result <= sum_combinatorial;
    end
  end

endmodule