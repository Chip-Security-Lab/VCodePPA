//SystemVerilog
module can_bit_timing #(
  parameter CLK_FREQ_MHZ = 20,
  parameter CAN_BITRATE_KBPS = 500
)(
  input wire clk, rst_n,
  input wire can_rx,
  output reg sample_point, sync_edge,
  output reg [2:0] segment
);
  
  // 计算每个比特的时钟周期数
  localparam integer TICKS_PER_BIT = (CLK_FREQ_MHZ * 1000) / CAN_BITRATE_KBPS;
  localparam integer SYNC_SEG = 1;
  localparam integer PROP_SEG = 1;
  localparam integer PHASE_SEG1 = 3;
  localparam integer PHASE_SEG2 = 3;
  localparam integer SAMPLE_POINT_POS = SYNC_SEG + PROP_SEG + PHASE_SEG1 - 1;
  
  reg [7:0] bit_counter;
  reg prev_rx;
  
  // 优化的比较逻辑和流水线信号
  wire sync_detected;
  wire counter_max;
  wire at_sample_point;
  
  // 优化的边缘检测逻辑
  assign sync_detected = prev_rx & ~can_rx;
  
  // 优化的比较器链
  assign counter_max = (bit_counter == TICKS_PER_BIT-1);
  assign at_sample_point = (bit_counter == SAMPLE_POINT_POS);
  
  // 时序逻辑阶段 - 更新寄存器和计数器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_counter <= 8'd0;
      segment <= 3'd0;
      prev_rx <= 1'b1;
      sample_point <= 1'b0;
      sync_edge <= 1'b0;
    end else begin
      prev_rx <= can_rx;
      sync_edge <= sync_detected;
      sample_point <= at_sample_point;
      
      if (sync_detected) begin
        // 同步重置
        bit_counter <= 8'd0;
        segment <= 3'd0;
      end else if (counter_max) begin
        // 计数器循环
        bit_counter <= 8'd0;
        segment <= segment + 3'd1;
      end else begin
        // 正常计数
        bit_counter <= bit_counter + 8'd1;
      end
    end
  end
endmodule