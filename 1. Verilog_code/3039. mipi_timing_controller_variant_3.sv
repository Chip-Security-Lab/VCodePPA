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

  reg [15:0] h_total_stage1, v_total_stage1;
  reg [15:0] h_count_stage1, v_count_stage1;
  reg h_count_reset_stage1, v_count_reset_stage1;
  reg [15:0] h_count_stage2, v_count_stage2;
  reg hsync_stage2, vsync_stage2;
  reg de_stage2;
  reg [15:0] h_count_stage3, v_count_stage3;
  reg hsync_stage3, vsync_stage3;
  reg de_stage3;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_total_stage1 <= h_active + h_front_porch + h_sync_width + h_back_porch;
      v_total_stage1 <= v_active + v_front_porch + v_sync_width + v_back_porch;
      h_count_stage1 <= 16'd0;
      v_count_stage1 <= 16'd0;
      h_count_reset_stage1 <= 1'b0;
      v_count_reset_stage1 <= 1'b0;
    end else begin
      h_total_stage1 <= h_active + h_front_porch + h_sync_width + h_back_porch;
      v_total_stage1 <= v_active + v_front_porch + v_sync_width + v_back_porch;
      
      if (h_count_stage1 < h_total_stage1 - 1) begin
        h_count_stage1 <= h_count_stage1 + 1'b1;
        h_count_reset_stage1 <= 1'b0;
      end else begin
        h_count_stage1 <= 16'd0;
        h_count_reset_stage1 <= 1'b1;
      end
      
      if (h_count_reset_stage1 && v_count_stage1 < v_total_stage1 - 1) begin
        v_count_stage1 <= v_count_stage1 + 1'b1;
        v_count_reset_stage1 <= 1'b0;
      end else if (h_count_reset_stage1) begin
        v_count_stage1 <= 16'd0;
        v_count_reset_stage1 <= 1'b1;
      end
    end
  end
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_count_stage2 <= 16'd0;
      v_count_stage2 <= 16'd0;
      hsync_stage2 <= 1'b0;
      vsync_stage2 <= 1'b0;
      de_stage2 <= 1'b0;
    end else begin
      h_count_stage2 <= h_count_stage1;
      v_count_stage2 <= v_count_stage1;
      
      hsync_stage2 <= (h_count_stage1 >= h_active + h_front_porch) && 
                     (h_count_stage1 < h_active + h_front_porch + h_sync_width);
      vsync_stage2 <= (v_count_stage1 >= v_active + v_front_porch) && 
                     (v_count_stage1 < v_active + v_front_porch + v_sync_width);
      de_stage2 <= (h_count_stage1 < h_active) && (v_count_stage1 < v_active);
    end
  end
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_count <= 16'd0;
      v_count <= 16'd0;
      hsync <= 1'b0;
      vsync <= 1'b0;
      de <= 1'b0;
    end else begin
      h_count <= h_count_stage2;
      v_count <= v_count_stage2;
      hsync <= hsync_stage2;
      vsync <= vsync_stage2;
      de <= de_stage2;
    end
  end
  
endmodule