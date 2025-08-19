//SystemVerilog
module multi_clock_shifter (
  input wire clk_a,
  input wire clk_b,
  input wire [7:0] data_in,
  input wire [2:0] shift_a,
  input wire [2:0] shift_b,
  output reg [7:0] data_out
);

  // Pipeline registers for left shift
  reg [7:0] left_shift_stage1;
  reg [7:0] left_shift_stage2;

  // Register for crossing clock domain
  reg [7:0] stage_a_reg;

  // Pipeline registers for right shift
  reg [7:0] right_shift_stage1;
  reg [7:0] right_shift_stage2;

  // ----------------------------
  // Left shift pipeline (clk_a)
  // ----------------------------

  // Stage 1: Handle shift_a[2]
  always @(posedge clk_a) begin
    if (shift_a[2])
      left_shift_stage1 <= {data_in[4:0], 3'b000};
    else
      left_shift_stage1 <= data_in;
  end

  // Stage 2: Handle shift_a[1] and shift_a[0]
  always @(posedge clk_a) begin
    reg [7:0] temp_left;
    if (shift_a[1])
      temp_left = {left_shift_stage1[6:0], 1'b0};
    else
      temp_left = left_shift_stage1;

    if (shift_a[0])
      left_shift_stage2 <= {temp_left[7:1], 1'b0};
    else
      left_shift_stage2 <= temp_left;
  end

  // Register output of left shifter for domain crossing
  always @(posedge clk_a) begin
    stage_a_reg <= left_shift_stage2;
  end

  // ------------------------------------
  // Right shift pipeline (clk_b)
  // ------------------------------------

  // Stage 1: Handle shift_b[2]
  always @(posedge clk_b) begin
    if (shift_b[2])
      right_shift_stage1 <= {3'b000, stage_a_reg[7:3]};
    else
      right_shift_stage1 <= stage_a_reg;
  end

  // Stage 2: Handle shift_b[1] and shift_b[0]
  always @(posedge clk_b) begin
    reg [7:0] temp_right;
    if (shift_b[1])
      temp_right = {1'b0, right_shift_stage1[7:1]};
    else
      temp_right = right_shift_stage1;

    if (shift_b[0])
      right_shift_stage2 <= {1'b0, temp_right[7:1]};
    else
      right_shift_stage2 <= temp_right;
  end

  // Final output register (clk_b)
  always @(posedge clk_b) begin
    data_out <= right_shift_stage2;
  end

endmodule