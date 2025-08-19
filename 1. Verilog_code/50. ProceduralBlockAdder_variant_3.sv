//SystemVerilog
//----------------------------------------------------------------------------
// Module: proc_adder
// Description: Pipelined 6-bit adder.
//   This module implements a 6-bit adder with a 2-stage pipeline
//   to improve timing performance and structure the data path.
//   Stage 0: Input registration
//   Stage 1: Addition computation and output registration
//----------------------------------------------------------------------------
module proc_adder(
  input wire clk,     // Clock signal for pipeline registers
  input wire rst_n,   // Asynchronous active-low reset
  input wire [5:0] p, // First 6-bit input operand
  input wire [5:0] q, // Second 6-bit input operand
  output reg [6:0] result // 7-bit output result (p + q)
);

  //----------------------------------------------------------------------------
  // Stage 0: Input Registration
  // Registers the input operands 'p' and 'q' at the rising edge of the clock.
  // These registers segment the input path and provide stable inputs for the
  // next pipeline stage (addition).
  // Reset initializes these registers to zero.
  //----------------------------------------------------------------------------
  reg [5:0] p_stage0_reg; // Registered value of input p
  reg [5:0] q_stage0_reg; // Registered value of input q

  //----------------------------------------------------------------------------
  // Stage 1: Addition Computation
  // Performs the addition operation using the registered inputs from Stage 0.
  // This is the combinational logic part of Stage 1.
  // The sum is computed based on the stable registered inputs.
  // The result of this computation is passed to the output registration.
  //----------------------------------------------------------------------------
  wire [6:0] sum_stage1_comb; // Combinational sum calculated in Stage 1

  // The addition of two 6-bit numbers (max 63 + 63 = 126) requires 7 bits.
  assign sum_stage1_comb = p_stage0_reg + q_stage0_reg; // Perform addition

  //----------------------------------------------------------------------------
  // Stage 0 & 1: Registration
  // Registers input operands and the final sum.
  // Combined logic for all sequential elements in the pipeline stages.
  // Reset initializes all registers to zero.
  //----------------------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all registers on active-low reset
      p_stage0_reg <= 6'b0;
      q_stage0_reg <= 6'b0;
      result <= 7'b0;
    end else begin
      // Latch inputs for Stage 0
      p_stage0_reg <= p;
      q_stage0_reg <= q;
      // Latch sum for Stage 1 output
      result <= sum_stage1_comb;
    end
  end

endmodule