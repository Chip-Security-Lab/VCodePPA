//SystemVerilog
module priority_reset_detector(
  input clk,
  input enable,
  input [7:0] reset_sources, // Active high
  input [7:0][2:0] priorities, // Lower value = higher priority
  output reg [2:0] active_priority,
  output reg [7:0] priority_encoded,
  output reg reset_out
);

  // Buffer for high fanout signal: reset_sources
  reg [7:0] reset_sources_buf1, reset_sources_buf2;

  // Internal registers for priority detection
  reg [2:0] highest_priority_reg;
  reg [2:0] highest_idx_reg;
  reg [7:0] priority_encoded_reg;
  reg reset_out_reg;
  reg [2:0] active_priority_reg;

  integer i;

  //==========================================================================
  // Buffering reset_sources to reduce fanout
  //==========================================================================
  always @(posedge clk) begin
    reset_sources_buf1 <= reset_sources;
    reset_sources_buf2 <= reset_sources_buf1;
  end

  //==========================================================================
  // Priority detection logic
  //==========================================================================
  always @(posedge clk) begin
    if (!enable) begin
      highest_priority_reg <= 3'h7;
      highest_idx_reg <= 3'd0;
    end else begin
      highest_priority_reg <= 3'h7;
      highest_idx_reg <= 3'd0;
      for (i = 0; i < 8; i = i + 1) begin
        if (reset_sources_buf2[i] && (priorities[i] < highest_priority_reg)) begin
          highest_priority_reg <= priorities[i];
          highest_idx_reg <= i[2:0];
        end
      end
    end
  end

  //==========================================================================
  // Output encoding logic
  //==========================================================================
  always @(posedge clk) begin
    if (!enable) begin
      active_priority_reg <= 3'h7;
      priority_encoded_reg <= 8'h00;
      reset_out_reg <= 1'b0;
    end else begin
      active_priority_reg <= highest_priority_reg;
      priority_encoded_reg <= (|reset_sources_buf2) ? (8'b1 << highest_idx_reg) : 8'h00;
      reset_out_reg <= |reset_sources_buf2;
    end
  end

  //==========================================================================
  // Output register assignment
  //==========================================================================
  always @(posedge clk) begin
    active_priority <= active_priority_reg;
    priority_encoded <= priority_encoded_reg;
    reset_out <= reset_out_reg;
  end

endmodule