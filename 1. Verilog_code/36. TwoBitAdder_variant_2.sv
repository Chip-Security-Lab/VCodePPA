//SystemVerilog
// SystemVerilog
module adder_4_pipelined (
  input wire        clk,
  input wire        rst_n,
  input wire [1:0]  a,
  input wire [1:0]  b,
  output wire [2:0] sum // sum is registered output
);

  // Stage 1: Combinatorial P and G calculation
  // Calculate propagate (p) and generate (g) signals for each bit
  wire [1:0] p_s1; // Propagate signals stage 1
  wire [1:0] g_s1; // Generate signals stage 1

  assign p_s1 = a ^ b;
  assign g_s1 = a & b;

  // Stage 2: Registered P and G signals
  // Register the results from Stage 1
  reg [1:0] p_s2; // Propagate signals stage 2 (registered)
  reg [1:0] g_s2; // Generate signals stage 2 (registered)

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      p_s2 <= 2'b0;
      g_s2 <= 2'b0;
    end else begin
      p_s2 <= p_s1;
      g_s2 <= g_s1;
    end
  end

  // Stage 3: Combinatorial Carry and partial Sum calculation
  // Calculate carries using lookahead logic and sum bits
  wire        c0 = 1'b0; // Assume carry-in is 0 for the LSB (constant)
  wire        c1_s3;     // Carry into bit 1 stage 3
  wire        c2_s3;     // Carry into bit 2 stage 3 (final carry out stage 3)
  wire        sum0_s3;   // Sum bit 0 stage 3
  wire        sum1_s3;   // Sum bit 1 stage 3
  wire        sum2_s3;   // Sum bit 2 stage 3 (MSB is final carry)

  // c[i+1] = g[i] | (p[i] & c[i])
  assign c1_s3 = g_s2[0] | (p_s2[0] & c0);   // Carry into bit 1 (using registered P/G)
  assign c2_s3 = g_s2[1] | (p_s2[1] & c1_s3); // Carry into bit 2 (using registered P/G and calculated c1)

  // sum[i] = p[i] ^ c[i]
  assign sum0_s3 = p_s2[0] ^ c0;   // Sum bit 0 (using registered P)
  assign sum1_s3 = p_s2[1] ^ c1_s3; // Sum bit 1 (using registered P and calculated c1)
  assign sum2_s3 = c2_s3;          // Sum bit 2 is the final carry out

  // Stage 4: Registered final Sum
  // Register the final sum result
  reg [2:0] sum_r; // Registered final sum

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum_r <= 3'b0;
    end else begin
      sum_r <= {sum2_s3, sum1_s3, sum0_s3};
    end
  end

  // Output assignment
  // The output is the registered sum from Stage 4
  assign sum = sum_r;

endmodule