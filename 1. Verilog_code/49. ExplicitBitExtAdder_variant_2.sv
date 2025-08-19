//SystemVerilog
module bitwise_add(
  input clk,
  input rst_n, // Active low reset
  input [2:0] a,
  input [2:0] b,
  output [3:0] total
);

  // Stage 1: Register inputs a and b
  reg [2:0] a_stage1_reg;
  reg [2:0] b_stage1_reg;

  // Stage 2: Perform addition and register the result
  wire [3:0] sum_stage2_comb; // Combinational sum from stage 1 registers
  reg [3:0] sum_stage2_reg;   // Registered sum for the output

  // Combine all sequential logic into a single always block
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset condition
      a_stage1_reg <= 3'b0;
      b_stage1_reg <= 3'b0;
      sum_stage2_reg <= 4'b0;
    end else begin
      // Normal operation on positive clock edge
      a_stage1_reg <= a;
      b_stage1_reg <= b;
      // Register the combinational sum from the previous stage
      sum_stage2_reg <= sum_stage2_comb;
    end
  end

  // Addition logic operating on registered inputs (combinational)
  assign sum_stage2_comb = {1'b0, a_stage1_reg} + {1'b0, b_stage1_reg};

  // Output: Connect module output to the final registered result
  assign total = sum_stage2_reg;

endmodule