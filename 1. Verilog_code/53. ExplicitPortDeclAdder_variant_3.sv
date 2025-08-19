//SystemVerilog
// SystemVerilog
// Top module: Instantiates the core adder logic
// This module serves as the top-level wrapper for the pipelined adder functionality.
module verbose_adder (
  input wire clk,         // Clock signal for pipelined operation
  input wire rst,         // Reset signal for pipelined registers (active high)
  input wire [1:0] data_a, // First 2-bit input operand
  input wire [1:0] data_b, // Second 2-bit input operand
  output wire [2:0] summation // 3-bit output sum (pipelined)
);

  // Instantiate the core pipelined adder module
  // Connects the top-level inputs and output to the core logic module.
  adder_core core_inst (
    .clk     (clk),       // Connect clock
    .rst     (rst),       // Connect reset
    .in_a    (data_a),    // Connect top-level input data_a to sub-module input in_a
    .in_b    (data_b),    // Connect top-level input data_b to sub-module input in_b
    .out_sum (summation)  // Connect sub-module output out_sum to top-level output summation
  );

endmodule

// Sub-module for the core pipelined addition logic
// This module encapsulates the 2-bit addition operation with a 1-stage pipeline.
module adder_core (
  input wire clk,         // Clock signal
  input wire rst,         // Reset signal (active high)
  input wire [1:0] in_a,   // First 2-bit input for addition
  input wire [1:0] in_b,   // Second 2-bit input for addition
  output wire [2:0] out_sum // 3-bit output representing the sum (registered)
);

  // Internal registers for pipeline stages
  reg [1:0] data_a_q;       // Registered input A
  reg [1:0] data_b_q;       // Registered input B
  reg [2:0] sum_q;        // Registered sum result

  // Pipeline stage 1: Register inputs and compute/register sum
  // Registers update on the positive clock edge or asynchronous reset
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // Asynchronous reset: clear all registers
      data_a_q <= 2'b0;
      data_b_q <= 2'b0;
      sum_q  <= 3'b0;
    end else begin
      // Synchronous update on clock edge
      // Register inputs
      data_a_q <= in_a;
      data_b_q <= in_b;
      // Compute and register sum from registered inputs
      sum_q <= data_a_q + data_b_q; // This forms the core pipeline stage (Reg -> Add -> Reg)
    end
  end

  // Output assignment from the final pipeline stage register
  // The output is the registered sum
  assign out_sum = sum_q;

endmodule