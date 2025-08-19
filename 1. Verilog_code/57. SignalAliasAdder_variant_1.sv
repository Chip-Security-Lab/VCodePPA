//SystemVerilog
// Top level module with pipelined data path
module alias_add(
  input clk,
  input rst_n,
  input [5:0] primary,
  input [5:0] secondary, 
  output reg [6:0] aggregate
);

  // Pipeline stage signals
  reg [5:0] primary_reg;
  reg [5:0] secondary_reg;
  reg [5:0] operand_A_reg;
  reg [5:0] operand_B_reg;
  reg [6:0] sum_reg;

  // Input processing stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      primary_reg <= 6'b0;
      secondary_reg <= 6'b0;
    end else begin
      primary_reg <= primary;
      secondary_reg <= secondary;
    end
  end

  // Operand processing stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      operand_A_reg <= 6'b0;
      operand_B_reg <= 6'b0;
    end else begin
      operand_A_reg <= primary_reg;
      operand_B_reg <= secondary_reg;
    end
  end

  // Addition stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum_reg <= 7'b0;
    end else begin
      sum_reg <= operand_A_reg + operand_B_reg;
    end
  end

  // Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aggregate <= 7'b0;
    end else begin
      aggregate <= sum_reg;
    end
  end

endmodule