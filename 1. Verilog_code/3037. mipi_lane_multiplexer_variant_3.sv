//SystemVerilog
module mipi_lane_multiplexer #(parameter LANES = 4) (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire valid_in,
  input wire [1:0] active_lanes,
  output reg [LANES-1:0] lane_data,
  output reg lane_valid
);

  // Stage 1: Input and Buffer Control
  reg [3:0] byte_counter_stage1;
  reg [31:0] data_buffer_stage1;
  reg [2:0] bytes_per_cycle_stage1;
  reg valid_stage1;
  
  // Stage 2: Data Processing
  reg [31:0] data_buffer_stage2;
  reg [1:0] active_lanes_stage2;
  reg [2:0] bytes_per_cycle_stage2;
  reg valid_stage2;
  
  // Stage 3: Output Generation
  reg [31:0] data_buffer_stage3;
  reg [1:0] active_lanes_stage3;
  reg [2:0] bytes_per_cycle_stage3;
  reg valid_stage3;

  // Optimized Stage 1 Logic
  wire [2:0] bytes_per_cycle_next = active_lanes + 1'b1;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      byte_counter_stage1 <= 4'd0;
      valid_stage1 <= 1'b0;
      bytes_per_cycle_stage1 <= 3'd1;
    end else begin
      valid_stage1 <= valid_in;
      if (valid_in) begin
        data_buffer_stage1[byte_counter_stage1*8 +: 8] <= data_in;
        byte_counter_stage1 <= (byte_counter_stage1 == bytes_per_cycle_next - 1) ? 
                              4'd0 : byte_counter_stage1 + 1'b1;
      end
      bytes_per_cycle_stage1 <= bytes_per_cycle_next;
    end
  end

  // Stage 2 Pipeline Register
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_buffer_stage2 <= 32'd0;
      active_lanes_stage2 <= 2'd0;
      bytes_per_cycle_stage2 <= 3'd0;
      valid_stage2 <= 1'b0;
    end else begin
      data_buffer_stage2 <= data_buffer_stage1;
      active_lanes_stage2 <= active_lanes;
      bytes_per_cycle_stage2 <= bytes_per_cycle_stage1;
      valid_stage2 <= valid_stage1;
    end
  end

  // Stage 3 Pipeline Register
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_buffer_stage3 <= 32'd0;
      active_lanes_stage3 <= 2'd0;
      bytes_per_cycle_stage3 <= 3'd0;
      valid_stage3 <= 1'b0;
    end else begin
      data_buffer_stage3 <= data_buffer_stage2;
      active_lanes_stage3 <= active_lanes_stage2;
      bytes_per_cycle_stage3 <= bytes_per_cycle_stage2;
      valid_stage3 <= valid_stage2;
    end
  end

  // Optimized Output Stage
  wire [31:0] lane_data_next;
  assign lane_data_next = (active_lanes_stage3 == 2'b00) ? {24'b0, data_buffer_stage3[7:0]} :
                         (active_lanes_stage3 == 2'b01) ? {16'b0, data_buffer_stage3[15:0]} :
                         (active_lanes_stage3 == 2'b10) ? {8'b0, data_buffer_stage3[23:0]} :
                         data_buffer_stage3;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      lane_data <= {LANES{1'b0}};
      lane_valid <= 1'b0;
    end else begin
      lane_valid <= valid_stage3;
      if (valid_stage3) begin
        lane_data <= lane_data_next[LANES-1:0];
      end
    end
  end

endmodule