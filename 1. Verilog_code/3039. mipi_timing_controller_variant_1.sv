//SystemVerilog
module mipi_timing_controller (
  input wire clk, reset_n,
  input wire [15:0] h_active, v_active,
  input wire [7:0] h_front_porch, h_back_porch,
  input wire [7:0] v_front_porch, v_back_porch,
  input wire [7:0] h_sync_width, v_sync_width,
  output reg hsync, vsync,
  output reg de,
  output reg [15:0] h_count, v_count
);

  // Stage 1: Total timing calculation
  reg [15:0] h_total_stage1, v_total_stage1;
  reg [15:0] h_active_stage1, v_active_stage1;
  reg [7:0] h_front_porch_stage1, v_front_porch_stage1;
  reg [7:0] h_sync_width_stage1, v_sync_width_stage1;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_active_stage1 <= 16'd0;
      v_active_stage1 <= 16'd0;
      h_front_porch_stage1 <= 8'd0;
      v_front_porch_stage1 <= 8'd0;
      h_sync_width_stage1 <= 8'd0;
      v_sync_width_stage1 <= 8'd0;
    end else begin
      h_active_stage1 <= h_active;
      v_active_stage1 <= v_active;
      h_front_porch_stage1 <= h_front_porch;
      v_front_porch_stage1 <= v_front_porch;
      h_sync_width_stage1 <= h_sync_width;
      v_sync_width_stage1 <= v_sync_width;
    end
  end

  // Stage 2: Calculate totals
  reg [15:0] h_total_stage2, v_total_stage2;
  reg [15:0] h_active_stage2, v_active_stage2;
  reg [7:0] h_front_porch_stage2, v_front_porch_stage2;
  reg [7:0] h_sync_width_stage2, v_sync_width_stage2;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_total_stage2 <= 16'd0;
      v_total_stage2 <= 16'd0;
      h_active_stage2 <= 16'd0;
      v_active_stage2 <= 16'd0;
      h_front_porch_stage2 <= 8'd0;
      v_front_porch_stage2 <= 8'd0;
      h_sync_width_stage2 <= 8'd0;
      v_sync_width_stage2 <= 8'd0;
    end else begin
      h_total_stage2 <= h_active_stage1 + h_front_porch_stage1 + h_sync_width_stage1 + h_back_porch;
      v_total_stage2 <= v_active_stage1 + v_front_porch_stage1 + v_sync_width_stage1 + v_back_porch;
      h_active_stage2 <= h_active_stage1;
      v_active_stage2 <= v_active_stage1;
      h_front_porch_stage2 <= h_front_porch_stage1;
      v_front_porch_stage2 <= v_front_porch_stage1;
      h_sync_width_stage2 <= h_sync_width_stage1;
      v_sync_width_stage2 <= v_sync_width_stage1;
    end
  end

  // Stage 3: Counter logic
  reg [15:0] h_count_stage3, v_count_stage3;
  wire h_count_reset_stage3, v_count_reset_stage3;

  assign h_count_reset_stage3 = (h_count_stage3 == h_total_stage2 - 1);
  assign v_count_reset_stage3 = (v_count_stage3 == v_total_stage2 - 1) && h_count_reset_stage3;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_count_stage3 <= 16'd0;
      v_count_stage3 <= 16'd0;
    end else begin
      if (h_count_reset_stage3)
        h_count_stage3 <= 16'd0;
      else
        h_count_stage3 <= h_count_stage3 + 1'b1;

      if (v_count_reset_stage3)
        v_count_stage3 <= 16'd0;
      else if (h_count_reset_stage3)
        v_count_stage3 <= v_count_stage3 + 1'b1;
    end
  end

  // Stage 4: Control signals calculation
  wire h_sync_active_stage4, v_sync_active_stage4, data_enable_stage4;

  assign h_sync_active_stage4 = (h_count_stage3 >= h_active_stage2 + h_front_porch_stage2) && 
                               (h_count_stage3 < h_active_stage2 + h_front_porch_stage2 + h_sync_width_stage2);
  assign v_sync_active_stage4 = (v_count_stage3 >= v_active_stage2 + v_front_porch_stage2) && 
                               (v_count_stage3 < v_active_stage2 + v_front_porch_stage2 + v_sync_width_stage2);
  assign data_enable_stage4 = (h_count_stage3 < h_active_stage2) && (v_count_stage3 < v_active_stage2);

  // Stage 5: Output registers
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      hsync <= 1'b0;
      vsync <= 1'b0;
      de <= 1'b0;
      h_count <= 16'd0;
      v_count <= 16'd0;
    end else begin
      hsync <= h_sync_active_stage4;
      vsync <= v_sync_active_stage4;
      de <= data_enable_stage4;
      h_count <= h_count_stage3;
      v_count <= v_count_stage3;
    end
  end

endmodule