//SystemVerilog
// SystemVerilog
// Submodule for zero extension
module zero_extend #(parameter N_IN = 4) (
  input [N_IN-1:0] data_in,
  output [N_IN:0] data_out
);
  // Function: Zero-extend the input data by 1 bit
  // This is Stage 1 combinational logic
  assign data_out = {1'b0, data_in};
endmodule

// Submodule for addition
module adder #(parameter N_WIDTH = 5) (
  input [N_WIDTH-1:0] a, b,
  output [N_WIDTH-1:0] sum
);
  // Function: Perform addition of two inputs
  // This is Stage 2 combinational logic
  assign sum = a + b;
endmodule

// Top module: Pipelined zero-extended adder
// This module orchestrates the data flow through pipeline stages
module cat_add_pipelined #(parameter N=4)(
  input clk, // Clock for pipeline registers
  input rst, // Synchronous reset for pipeline registers
  input [N-1:0] in1, // Input 1 (N bits)
  input [N-1:0] in2, // Input 2 (N bits)
  output [N:0] out // Registered output (N+1 bits)
);

  // --- Pipeline Stage 1: Zero Extension and Registering ---

  // Wires for the combinational output of the zero_extend modules
  // These are the outputs of the first stage combinational logic
  wire [N:0] in1_extended_stage1_comb;
  wire [N:0] in2_extended_stage1_comb;

  // Registers to hold the outputs of Stage 1 combinational logic
  // These signals feed the next pipeline stage
  reg [N:0] in1_extended_stage1_reg;
  reg [N:0] in2_extended_stage1_reg;

  // Instantiate zero_extend module for in1 (Stage 1 combinational)
  zero_extend #(
    .N_IN(N)
  ) zero_extend_in1_inst (
    .data_in(in1),
    .data_out(in1_extended_stage1_comb)
  );

  // Instantiate zero_extend module for in2 (Stage 1 combinational)
  zero_extend #(
    .N_IN(N)
  ) zero_extend_in2_inst (
    .data_in(in2),
    .data_out(in2_extended_stage1_comb)
  );

  // Register the outputs of Stage 1 combinational logic
  // This forms the sequential part of Stage 1
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      in1_extended_stage1_reg <= {(N+1){1'b0}};
      in2_extended_stage1_reg <= {(N+1){1'b0}};
    end else begin
      in1_extended_stage1_reg <= in1_extended_stage1_comb;
      in2_extended_stage1_reg <= in2_extended_stage1_comb;
    end
  end

  // --- Pipeline Stage 2: Addition and Registering ---

  // Wire for the combinational output of the adder module
  // This is the output of the second stage combinational logic
  wire [N:0] sum_stage2_comb;

  // Register to hold the output of Stage 2 combinational logic
  // This register provides the final output after 2 pipeline stages
  reg [N:0] sum_stage2_reg;

  // Instantiate adder module (Stage 2 combinational)
  // It takes the registered outputs from Stage 1 as inputs
  adder #(
    .N_WIDTH(N + 1) // Adder width is N+1
  ) adder_inst (
    .a(in1_extended_stage1_reg), // Use registered input from Stage 1
    .b(in2_extended_stage1_reg), // Use registered input from Stage 1
    .sum(sum_stage2_comb)
  );

  // Register the output of Stage 2 combinational logic
  // This forms the sequential part of Stage 2 and registers the final result
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      sum_stage2_reg <= {(N+1){1'b0}};
    end else begin
      sum_stage2_reg <= sum_stage2_comb;
    end
  end

  // Assign the final registered output to the module output port
  assign out = sum_stage2_reg;

endmodule