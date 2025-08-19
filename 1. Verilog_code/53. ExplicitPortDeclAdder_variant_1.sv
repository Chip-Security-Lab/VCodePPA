//SystemVerilog
module pipelined_adder (
  input wire clk,
  input wire rst_n,
  input wire [1:0] data_a,
  input wire [1:0] data_b,
  output wire [2:0] summation
);

  // Stage 0: Generate P and G signals (Combinational)
  // p_s0[i] = data_a[i] ^ data_b[i] (Propagate)
  // g_s0[i] = data_a[i] & data_b[i] (Generate)
  wire [1:0] p_s0;
  wire [1:0] g_s0;

  assign p_s0[0] = data_a[0] ^ data_b[0];
  assign g_s0[0] = data_a[0] & data_b[0];
  assign p_s0[1] = data_a[1] ^ data_b[1];
  assign g_s0[1] = data_a[1] & data_b[1];

  // Stage 1: Register P and G signals
  // These signals represent the P and G values from the previous clock cycle
  reg [1:0] p_s1;
  reg [1:0] g_s1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      p_s1 <= 2'b0;
      g_s1 <= 2'b0;
    end else begin
      p_s1 <= p_s0;
      g_s1 <= g_s0;
    end
  end

  // Stage 2: Calculate Carries and Sums (Combinational)
  // Uses the registered P and G values
  // c_s2[i] is the carry-out of bit i
  // s_s2[i] is the sum bit i
  wire [1:0] c_s2;
  wire [1:0] s_s2;

  // Carry calculation using parallel prefix logic (c[i] = G[i:0])
  // Assuming carry-in to bit 0 is 0
  // c_s2[0] = G[0] = g_s1[0]
  assign c_s2[0] = g_s1[0];
  // c_s2[1] = G[1:0] = g_s1[1] | (p_s1[1] & G[0]) = g_s1[1] | (p_s1[1] & c_s2[0])
  assign c_s2[1] = g_s1[1] | (p_s1[1] & c_s2[0]);

  // Sum calculation (s[i] = p[i] ^ C[i-1])
  // s_s2[0] = p_s1[0] ^ C[-1] = p_s1[0] ^ 0
  assign s_s2[0] = p_s1[0]; // Equivalent to p_s1[0] ^ 1'b0
  // s_s2[1] = p_s1[1] ^ C[0] = p_s1[1] ^ c_s2[0]
  assign s_s2[1] = p_s1[1] ^ c_s2[0];

  // Output assignment
  // summation[2:0] = {carry_out_bit1, sum_bit1, sum_bit0}
  assign summation[0] = s_s2[0];
  assign summation[1] = s_s2[1];
  assign summation[2] = c_s2[1]; // Carry out of the most significant bit

endmodule