//SystemVerilog
module Top_OR_Module (
  input logic clk,
  input logic rst_n,
  input logic [1:0] a_in,
  input logic [1:0] b_in,
  output logic [3:0] y_out
);

  // Stage 1: Register inputs
  logic [1:0] a_reg;
  logic [1:0] b_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_reg <= 2'b00;
      b_reg <= 2'b00;
    end else begin
      a_reg <= a_in;
      b_reg <= b_in;
    end
  end

  // Stage 2: Perform OR operation
  logic [1:0] or_stage_out;

  OR_Logic_Submodule or_logic_inst (
    .input_a(a_reg),
    .input_b(b_reg),
    .output_or(or_stage_out)
  );

  // Stage 3: Register OR results and combine with fixed bits
  logic [3:0] y_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      y_reg <= 4'b0000;
    end else begin
      y_reg[3:2] <= 2'b11;
      y_reg[1:0] <= or_stage_out;
    end
  end

  // Output stage
  assign y_out = y_reg;

endmodule

// Submodule for performing bitwise OR operations
module OR_Logic_Submodule (
  input logic [1:0] input_a, input_b,
  output logic [1:0] output_or
);

  // Perform bitwise OR
  assign output_or = input_a | input_b;

endmodule