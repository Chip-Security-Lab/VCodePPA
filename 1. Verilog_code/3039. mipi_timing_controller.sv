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
  reg [15:0] h_total, v_total;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_count <= 16'd0;
      v_count <= 16'd0;
      hsync <= 1'b0;
      vsync <= 1'b0;
      de <= 1'b0;
      h_total <= h_active + h_front_porch + h_sync_width + h_back_porch;
      v_total <= v_active + v_front_porch + v_sync_width + v_back_porch;
    end else begin
      // Counters
      if (h_count < h_total - 1)
        h_count <= h_count + 1'b1;
      else begin
        h_count <= 16'd0;
        if (v_count < v_total - 1)
          v_count <= v_count + 1'b1;
        else
          v_count <= 16'd0;
      end
      
      // Sync signals
      hsync <= (h_count >= h_active + h_front_porch) && 
               (h_count < h_active + h_front_porch + h_sync_width);
      vsync <= (v_count >= v_active + v_front_porch) && 
               (v_count < v_active + v_front_porch + v_sync_width);
      
      // Data enable
      de <= (h_count < h_active) && (v_count < v_active);
    end
  end
endmodule
