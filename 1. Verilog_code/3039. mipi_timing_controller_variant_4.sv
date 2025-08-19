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

  // Stage 1: Input buffering and total calculations
  reg [15:0] h_total_stage1, v_total_stage1;
  reg [15:0] h_active_stage1, v_active_stage1;
  reg [7:0] h_front_porch_stage1, h_back_porch_stage1;
  reg [7:0] v_front_porch_stage1, v_back_porch_stage1;
  reg [7:0] h_sync_width_stage1, v_sync_width_stage1;

  // Stage 2: Counter calculations
  reg [15:0] h_count_stage2, v_count_stage2;
  reg [15:0] h_total_stage2, v_total_stage2;
  reg [15:0] h_active_stage2, v_active_stage2;
  reg [7:0] h_front_porch_stage2, v_front_porch_stage2;
  reg [7:0] h_sync_width_stage2, v_sync_width_stage2;

  // Stage 3: Sync and DE calculations
  reg hsync_stage3, vsync_stage3;
  reg de_stage3;
  reg [15:0] h_count_stage3, v_count_stage3;
  reg [15:0] h_active_stage3, v_active_stage3;
  reg [7:0] h_front_porch_stage3, v_front_porch_stage3;
  reg [7:0] h_sync_width_stage3, v_sync_width_stage3;

  // Stage 1: Input buffering and total calculations
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_total_stage1 <= 16'd0;
      v_total_stage1 <= 16'd0;
      h_active_stage1 <= 16'd0;
      v_active_stage1 <= 16'd0;
      h_front_porch_stage1 <= 8'd0;
      h_back_porch_stage1 <= 8'd0;
      v_front_porch_stage1 <= 8'd0;
      v_back_porch_stage1 <= 8'd0;
      h_sync_width_stage1 <= 8'd0;
      v_sync_width_stage1 <= 8'd0;
    end else begin
      h_active_stage1 <= h_active;
      v_active_stage1 <= v_active;
      h_front_porch_stage1 <= h_front_porch;
      h_back_porch_stage1 <= h_back_porch;
      v_front_porch_stage1 <= v_front_porch;
      v_back_porch_stage1 <= v_back_porch;
      h_sync_width_stage1 <= h_sync_width;
      v_sync_width_stage1 <= v_sync_width;
      h_total_stage1 <= h_active + h_front_porch + h_sync_width + h_back_porch;
      v_total_stage1 <= v_active + v_front_porch + v_sync_width + v_back_porch;
    end
  end

  // Stage 2: Counter calculations
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_count_stage2 <= 16'd0;
      v_count_stage2 <= 16'd0;
      h_total_stage2 <= 16'd0;
      v_total_stage2 <= 16'd0;
      h_active_stage2 <= 16'd0;
      v_active_stage2 <= 16'd0;
      h_front_porch_stage2 <= 8'd0;
      v_front_porch_stage2 <= 8'd0;
      h_sync_width_stage2 <= 8'd0;
      v_sync_width_stage2 <= 8'd0;
    end else begin
      h_total_stage2 <= h_total_stage1;
      v_total_stage2 <= v_total_stage1;
      h_active_stage2 <= h_active_stage1;
      v_active_stage2 <= v_active_stage1;
      h_front_porch_stage2 <= h_front_porch_stage1;
      v_front_porch_stage2 <= v_front_porch_stage1;
      h_sync_width_stage2 <= h_sync_width_stage1;
      v_sync_width_stage2 <= v_sync_width_stage1;

      if (h_count < h_total_stage1 - 1)
        h_count_stage2 <= h_count + 1'b1;
      else begin
        h_count_stage2 <= 16'd0;
        if (v_count < v_total_stage1 - 1)
          v_count_stage2 <= v_count + 1'b1;
        else
          v_count_stage2 <= 16'd0;
      end
    end
  end

  // Stage 3: Sync and DE calculations
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      hsync_stage3 <= 1'b0;
      vsync_stage3 <= 1'b0;
      de_stage3 <= 1'b0;
      h_count_stage3 <= 16'd0;
      v_count_stage3 <= 16'd0;
      h_active_stage3 <= 16'd0;
      v_active_stage3 <= 16'd0;
      h_front_porch_stage3 <= 8'd0;
      v_front_porch_stage3 <= 8'd0;
      h_sync_width_stage3 <= 8'd0;
      v_sync_width_stage3 <= 8'd0;
    end else begin
      h_count_stage3 <= h_count_stage2;
      v_count_stage3 <= v_count_stage2;
      h_active_stage3 <= h_active_stage2;
      v_active_stage3 <= v_active_stage2;
      h_front_porch_stage3 <= h_front_porch_stage2;
      v_front_porch_stage3 <= v_front_porch_stage2;
      h_sync_width_stage3 <= h_sync_width_stage2;
      v_sync_width_stage3 <= v_sync_width_stage2;

      hsync_stage3 <= (h_count_stage2 >= h_active_stage2 + h_front_porch_stage2) && 
                     (h_count_stage2 < h_active_stage2 + h_front_porch_stage2 + h_sync_width_stage2);
      vsync_stage3 <= (v_count_stage2 >= v_active_stage2 + v_front_porch_stage2) && 
                     (v_count_stage2 < v_active_stage2 + v_front_porch_stage2 + v_sync_width_stage2);
      de_stage3 <= (h_count_stage2 < h_active_stage2) && (v_count_stage2 < v_active_stage2);
    end
  end

  // Output stage
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      hsync <= 1'b0;
      vsync <= 1'b0;
      de <= 1'b0;
      h_count <= 16'd0;
      v_count <= 16'd0;
    end else begin
      hsync <= hsync_stage3;
      vsync <= vsync_stage3;
      de <= de_stage3;
      h_count <= h_count_stage3;
      v_count <= v_count_stage3;
    end
  end

endmodule