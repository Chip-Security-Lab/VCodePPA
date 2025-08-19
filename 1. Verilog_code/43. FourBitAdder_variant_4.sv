//SystemVerilog
module adder_11 (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [4:0] sum
);

  // Operation bit width is 4 for inputs a and b, 5 for sum (includes carry-out)
  parameter N = 4;

  // Generate and Propagate for each bit
  // p_in[i] = a[i] ^ b[i]
  // g_in[i] = a[i] & b[i]
  wire [N-1:0] p_in;
  wire [N-1:0] g_in;

  assign p_in = a ^ b;
  assign g_in = a & b;

  // Carries using direct carry-lookahead formulas derived from prefix tree
  // c[i+1] = G_i^(log2 N) assuming C_0 = 0
  wire [N:0] carries; // N+1 carries for N bits

  assign carries[0] = 1'b0; // Input carry (assumed 0 based on original code)

  // c[1] = g_in[0]
  assign carries[1] = g_in[0];

  // c[2] = g_in[1] | (p_in[1] & g_in[0])
  assign carries[2] = g_in[1] | (p_in[1] & g_in[0]);

  // c[3] = g_in[2] | (p_in[2] & g_in[1]) | (p_in[2] & p_in[1] & g_in[0])
  assign carries[3] = g_in[2] | (p_in[2] & g_in[1]) | (p_in[2] & p_in[1] & g_in[0]);

  // c[4] = g_in[3] | (p_in[3] & g_in[2]) | (p_in[3] & p_in[2] & g_in[1]) | (p_in[3] & p_in[2] & p_in[1] & g_in[0])
  assign carries[4] = g_in[3] | (p_in[3] & g_in[2]) | (p_in[3] & p_in[2] & g_in[1]) | (p_in[3] & p_in[2] & p_in[1] & g_in[0]);

  // Sum bits
  // sum_bits[i] = p_in[i] ^ carries[i]
  wire [N-1:0] sum_bits;

  assign sum_bits[0] = p_in[0] ^ carries[0]; // carries[0] is 0
  assign sum_bits[1] = p_in[1] ^ carries[1];
  assign sum_bits[2] = p_in[2] ^ carries[2];
  assign sum_bits[3] = p_in[3] ^ carries[3];

  // Final sum output: {carry_out, sum_bits}
  assign sum = {carries[N], sum_bits}; // sum[4] is carry_out, sum[3:0] are sum_bits

endmodule