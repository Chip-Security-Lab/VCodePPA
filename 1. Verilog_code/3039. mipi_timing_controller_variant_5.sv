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

  reg [15:0] h_total, v_total;
  wire h_count_overflow, v_count_overflow;
  wire h_sync_active, v_sync_active;
  wire data_enable;

  // Calculate total periods
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_total <= h_active + h_front_porch + h_sync_width + h_back_porch;
      v_total <= v_active + v_front_porch + v_sync_width + v_back_porch;
    end
  end

  // Horizontal counter logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      h_count <= 16'd0;
    end else begin
      h_count <= (h_count < h_total - 1) ? h_count + 1'b1 : 16'd0;
    end
  end

  // Vertical counter logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      v_count <= 16'd0;
    end else begin
      v_count <= (h_count == h_total - 1) ? 
                 ((v_count < v_total - 1) ? v_count + 1'b1 : 16'd0) : 
                 v_count;
    end
  end

  // Horizontal sync signal generation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      hsync <= 1'b0;
    end else begin
      hsync <= (h_count >= h_active + h_front_porch) && 
               (h_count < h_active + h_front_porch + h_sync_width);
    end
  end

  // Vertical sync signal generation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      vsync <= 1'b0;
    end else begin
      vsync <= (v_count >= v_active + v_front_porch) && 
               (v_count < v_active + v_front_porch + v_sync_width);
    end
  end

  // Data enable signal generation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      de <= 1'b0;
    end else begin
      de <= (h_count < h_active) && (v_count < v_active);
    end
  end

endmodule