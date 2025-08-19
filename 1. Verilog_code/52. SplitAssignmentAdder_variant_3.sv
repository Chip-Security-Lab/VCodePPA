//SystemVerilog
// Top Module (Pipelined version)
module split_add (
  input clk, // Clock input for pipelining
  input rst, // Reset input for register initialization
  input [7:0] m,
  input [7:0] n,
  output [8:0] total
);

  // Wire to connect the combinational adder output to the register input
  wire [8:0] adder_result;

  // Register to hold the pipelined sum before output
  reg [8:0] pipelined_sum_reg;

  // Instantiate the combinational adder module
  combinational_adder adder_inst (
    .in1(m),
    .in2(n),
    .sum_out(adder_result)
  );

  // Sequential logic: Register the combinational sum
  // This stage captures the result of the addition on the clock edge
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pipelined_sum_reg <= 9'b0; // Reset the register to zero
    end else begin
      pipelined_sum_reg <= adder_result; // Capture the sum from the combinational block
    end
  end

  // Assign the registered value to the output
  // The output 'total' is the result from the pipeline register
  assign total = pipelined_sum_reg;

endmodule

// Combinational Adder Module
module combinational_adder (
  input [7:0] in1,
  input [7:0] in2,
  output [8:0] sum_out
);

  // Perform the addition using assign statement for pure combinational logic
  assign sum_out = in1 + in2;

endmodule