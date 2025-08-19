//SystemVerilog
module bitwise_add(
  input wire clk,      // Clock signal for pipelining
  input wire rst_n,    // Active low reset
  input wire [2:0] a,
  input wire [2:0] b,
  output reg [3:0] total // Pipelined output
);

  // Extend inputs to 4 bits for the adder
  wire [3:0] a_ext;
  wire [3:0] b_ext;
  assign a_ext = {1'b0, a};
  assign b_ext = {1'b0, b};

  // Wires for Manchester Carry Chain internal signals
  // P = A_ext ^ B_ext (Propagate)
  wire [3:0] mcc_propagate;
  // G = A_ext & B_ext (Generate)
  wire [3:0] mcc_generate;
  // Carry chain C[0] is input carry, C[1..4] are stage carries
  wire [4:0] mcc_carry;

  // Combinational logic for the 4-bit Manchester Carry Chain adder
  // Calculate Propagate and Generate signals for each bit position (0 to 3)
  assign mcc_propagate = a_ext ^ b_ext;
  assign mcc_generate  = a_ext & b_ext;

  // Calculate carry chain
  // mcc_carry[0] is the input carry, which is 0 for simple addition
  assign mcc_carry[0] = 1'b0;
  // mcc_carry[i+1] = mcc_generate[i] | (mcc_propagate[i] & mcc_carry[i])
  assign mcc_carry[1] = mcc_generate[0] | (mcc_propagate[0] & mcc_carry[0]);
  assign mcc_carry[2] = mcc_generate[1] | (mcc_propagate[1] & mcc_carry[1]);
  assign mcc_carry[3] = mcc_generate[2] | (mcc_propagate[2] & mcc_carry[2]);
  assign mcc_carry[4] = mcc_generate[3] | (mcc_propagate[3] & mcc_carry[3]); // Final carry out

  // Calculate sum bits S[i] = P[i] ^ C[i]
  wire [3:0] combinational_sum_w; // Sum output of the combinational adder
  assign combinational_sum_w[0] = mcc_propagate[0] ^ mcc_carry[0];
  assign combinational_sum_w[1] = mcc_propagate[1] ^ mcc_carry[1];
  assign combinational_sum_w[2] = mcc_propagate[2] ^ mcc_carry[2];
  assign combinational_sum_w[3] = mcc_propagate[3] ^ mcc_carry[3]; // Note: mcc_propagate[3] is 0, so sum[3] = mcc_carry[3]

  // Stage 2: Sequential registration
  // This register stores the result of the combinational sum on the clock edge
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset the output to a known state
      total <= 4'b0;
    end else begin
      // Register the computed sum
      total <= combinational_sum_w;
    end
  end

endmodule