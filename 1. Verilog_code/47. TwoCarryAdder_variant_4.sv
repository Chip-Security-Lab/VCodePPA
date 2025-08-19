//SystemVerilog
module adder_15 (
    input wire        clk,    // Clock signal
    input wire        rst,    // Asynchronous reset signal
    input wire        a,      // First input bit
    input wire        b,      // Second input bit
    input wire        c_in,   // Carry-in bit
    output reg        sum,    // Sum output bit (registered)
    output reg        carry   // Carry-out bit (registered)
);

  // Internal wires for combinational results
  wire sum_comb;
  wire carry_comb;

  // Intermediate signals to restructure and potentially balance paths
  wire a_xor_b; // a ^ b
  wire a_and_b; // a & b
  wire a_or_b;  // a | b

  // Stage 1: Calculate basic combinations of inputs a and b in parallel
  // These signals are used in the calculation of both sum and carry
  assign a_xor_b = a ^ b;
  assign a_and_b = a & b;
  assign a_or_b  = a | b; // Useful for the conditional carry calculation

  // Stage 2: Calculate combinational sum and carry using intermediate signals
  // Sum calculation remains a 3-input XOR
  assign sum_comb  = a_xor_b ^ c_in;

  // Carry calculation restructured using conditional logic (MUX based)
  // This form is equivalent to (a & b) | ((a | b) & c_in)
  // If c_in is 1, carry is (a | b). If c_in is 0, carry is (a & b).
  assign carry_comb = c_in ? a_or_b : a_and_b;

  // Stage 3: Register combinational results on clock edge
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      sum   <= 1'b0;
      carry <= 1'b0;
    end else begin
      sum   <= sum_comb;
      carry <= carry_comb;
    end
  end

  // The data path is now structured into:
  // Input -> Basic A/B Combinations (Stage 1) -> Final Comb Logic (Stage 2) -> Registers (Stage 3) -> Output
  // This restructuring reorganizes the carry logic into a conditional (MUX) form,
  // potentially affecting the critical path delay depending on the target technology library.

endmodule