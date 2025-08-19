//SystemVerilog
// SystemVerilog
module glitch_filter_reset_detector(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        raw_reset,
  output reg         filtered_reset
);

  reg  [7:0] shift_reg;
  reg  [3:0] popcount_stage1;
  reg  [3:0] popcount_stage2;
  reg        majority_detected_stage2;
  reg        filtered_reset_stage1;

  // 优化的计数'1'数量的函数
  function [3:0] popcount8;
    input [7:0] d;
    reg [3:0] sum1, sum2;
    begin
      sum1 = d[0] + d[1] + d[2] + d[3];
      sum2 = d[4] + d[5] + d[6] + d[7];
      popcount8 = sum1 + sum2;
    end
  endfunction

  //--------------------------------------------------------------------------
  // Shift Register Update
  //--------------------------------------------------------------------------
  // Handles the serial shifting of raw_reset into the shift register.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], raw_reset};
    end
  end

  //--------------------------------------------------------------------------
  // Popcount Calculation Stage 1
  //--------------------------------------------------------------------------
  // Calculates the number of '1's in the shift register after update.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      popcount_stage1 <= 4'b0;
    end else begin
      popcount_stage1 <= popcount8({shift_reg[6:0], raw_reset});
    end
  end

  //--------------------------------------------------------------------------
  // Popcount Registering and Majority Detection Stage 2
  //--------------------------------------------------------------------------
  // Registers popcount and detects if majority of shift_reg bits are '1'.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      popcount_stage2          <= 4'b0;
      majority_detected_stage2 <= 1'b0;
    end else begin
      popcount_stage2          <= popcount_stage1;
      majority_detected_stage2 <= (popcount_stage1 >= 4'd5);
    end
  end

  //--------------------------------------------------------------------------
  // Filtered Reset Stage 1 Logic (Hysteresis)
  //--------------------------------------------------------------------------
  // Implements hysteresis for filtered reset logic.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      filtered_reset_stage1 <= 1'b0;
    end else begin
      if (filtered_reset_stage1) begin
        if (!majority_detected_stage2) begin
          filtered_reset_stage1 <= |shift_reg[7:6];
        end else begin
          filtered_reset_stage1 <= 1'b1;
        end
      end else begin
        filtered_reset_stage1 <= majority_detected_stage2;
      end
    end
  end

  //--------------------------------------------------------------------------
  // Filtered Reset Output Registering
  //--------------------------------------------------------------------------
  // Registers the final filtered reset output.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      filtered_reset <= 1'b0;
    end else begin
      filtered_reset <= filtered_reset_stage1;
    end
  end

endmodule