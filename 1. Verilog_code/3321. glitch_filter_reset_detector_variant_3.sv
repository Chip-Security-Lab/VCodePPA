//SystemVerilog
module glitch_filter_reset_detector(
  input clk,
  input rst_n,
  input raw_reset,
  output reg filtered_reset
);

  reg [7:0] shift_reg;
  reg reset_detected;
  wire [3:0] ones_count;
  reg [1:0] detect_count;
  reg [1:0] clear_count;
  reg reset_detected_d;

  // Pipeline register for shift_reg to break critical path in ones_count calculation
  reg [7:0] shift_reg_pipe;

  // Pipeline register for ones_count to break critical path in reset_detected logic
  reg [3:0] ones_count_pipe;

  // 用函数替代$countones系统函数
  function [3:0] count_ones;
    input [7:0] data;
    integer i;
    begin
      count_ones = 0;
      for (i = 0; i < 8; i = i + 1)
        if (data[i]) count_ones = count_ones + 1;
    end
  endfunction

  // Stage 1: Shift register for raw_reset input
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      shift_reg <= 8'h00;
    else
      shift_reg <= {shift_reg[6:0], raw_reset};
  end

  // Stage 2: Pipeline shift_reg to break critical path
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      shift_reg_pipe <= 8'h00;
    else
      shift_reg_pipe <= shift_reg;
  end

  // Stage 3: Count ones from pipelined shift_reg
  assign ones_count = count_ones(shift_reg_pipe);

  // Stage 4: Pipeline ones_count to break critical path before majority detection
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      ones_count_pipe <= 4'd0;
    else
      ones_count_pipe <= ones_count;
  end

  // Stage 5: Majority detection logic (pipelined)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      reset_detected <= 1'b0;
    else
      reset_detected <= (ones_count_pipe >= 4'd5);
  end

  // Stage 6: Delay register for reset_detected (for hysteresis check)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      reset_detected_d <= 1'b0;
    else
      reset_detected_d <= reset_detected;
  end

  // Stage 7: Hysteresis detection (consecutive detection counter)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      detect_count <= 2'd0;
    else if (reset_detected)
      if (detect_count != 2'd2)
        detect_count <= detect_count + 1'b1;
      else
        detect_count <= detect_count;
    else
      detect_count <= 2'd0;
  end

  // Stage 8: Hysteresis clearing (consecutive clear counter)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      clear_count <= 2'd0;
    else if (!reset_detected)
      if (clear_count != 2'd2)
        clear_count <= clear_count + 1'b1;
      else
        clear_count <= clear_count;
    else
      clear_count <= 2'd0;
  end

  // Stage 9: Filtered reset output logic with hysteresis
  // Adjust for pipeline delay: shift_reg_pipe is delayed by 1, shift_reg is delayed by 2 cycles
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      filtered_reset <= 1'b0;
    end else begin
      if (detect_count == 2'd2)
        filtered_reset <= 1'b1;
      else if (clear_count == 2'd2)
        filtered_reset <= shift_reg_pipe[7:6] != 2'b00;
      else if (!reset_detected && !reset_detected_d)
        filtered_reset <= 1'b0;
    end
  end

endmodule