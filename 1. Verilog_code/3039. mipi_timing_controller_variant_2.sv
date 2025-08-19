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

  // Pre-calculate total values with optimized bit widths
  reg [15:0] h_total, v_total;
  reg [15:0] h_active_plus_front, v_active_plus_front;
  reg [15:0] h_sync_start_val, v_sync_start_val;
  reg [15:0] h_sync_end_val, v_sync_end_val;
  
  // Optimized comparison signals with reduced logic depth
  wire h_count_max = (h_count == h_total - 1);
  wire v_count_max = (v_count == v_total - 1);
  wire h_sync_active = (h_count >= h_sync_start_val) && (h_count < h_sync_end_val);
  wire v_sync_active = (v_count >= v_sync_start_val) && (v_count < v_sync_end_val);
  wire active_region = (h_count < h_active) && (v_count < v_active);
  
  // Pre-calculate sync boundaries with optimized arithmetic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_active_plus_front <= h_active + h_front_porch;
      v_active_plus_front <= v_active + v_front_porch;
      h_sync_start_val <= h_active_plus_front;
      v_sync_start_val <= v_active_plus_front;
      h_sync_end_val <= h_active_plus_front + h_sync_width;
      v_sync_end_val <= v_active_plus_front + v_sync_width;
      h_total <= h_sync_end_val + h_back_porch;
      v_total <= v_sync_end_val + v_back_porch;
    end
  end
  
  // Optimized counter and control logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_count <= 16'd0;
      v_count <= 16'd0;
      hsync <= 1'b0;
      vsync <= 1'b0;
      de <= 1'b0;
    end else begin
      // Horizontal counter with optimized increment
      h_count <= h_count_max ? 16'd0 : h_count + 1'b1;
      
      // Vertical counter with optimized condition
      v_count <= h_count_max ? (v_count_max ? 16'd0 : v_count + 1'b1) : v_count;
      
      // Sync signals with optimized logic
      hsync <= h_sync_active;
      vsync <= v_sync_active;
      
      // Data enable with optimized condition
      de <= active_region;
    end
  end
endmodule