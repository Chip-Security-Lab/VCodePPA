//SystemVerilog
// Top level module with pipelined data flow
module documented_adder (
  input  logic        clk,            // Clock signal (added for pipelining)
  input  logic        rst_n,          // Reset signal (added for pipelining)
  input  logic signed [7:0] operand_x,
  input  logic signed [7:0] operand_y,
  output logic signed [8:0] sum_result
);

  // Pipeline stage signals
  logic signed [7:0] x_stage1, y_stage1;
  logic signed [7:0] sum_low_stage1;
  logic        carry_out_stage1;
  logic        overflow_stage2;
  logic signed [7:0] sum_low_stage2;

  // Stage 1: Input registration and core addition
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      x_stage1 <= 8'b0;
      y_stage1 <= 8'b0;
      sum_low_stage1 <= 8'b0;
      carry_out_stage1 <= 1'b0;
    end else begin
      x_stage1 <= operand_x;
      y_stage1 <= operand_y;
      // Perform addition in the first stage
      {carry_out_stage1, sum_low_stage1} <= operand_x + operand_y;
    end
  end

  // Stage 2: Overflow detection and result formation
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      overflow_stage2 <= 1'b0;
      sum_low_stage2 <= 8'b0;
      sum_result <= 9'b0;
    end else begin
      // Calculate overflow in the second stage
      overflow_stage2 <= (x_stage1[7] == y_stage1[7]) && (sum_low_stage1[7] != x_stage1[7]);
      sum_low_stage2 <= sum_low_stage1;
      // Form final result
      sum_result <= {overflow_stage2, sum_low_stage2};
    end
  end

endmodule