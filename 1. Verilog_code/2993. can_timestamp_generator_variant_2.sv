//SystemVerilog
// SystemVerilog
module can_timestamp_generator(
  input wire clk, rst_n,
  input wire can_rx_edge, can_frame_start, can_frame_end,
  output reg [31:0] current_timestamp,
  output reg [31:0] frame_timestamp,
  output reg timestamp_valid
);
  // 流水线寄存器与控制信号
  reg [15:0] prescaler_counter;
  reg increment_timestamp;
  
  // 流水线状态寄存器
  reg can_frame_start_stage1, can_frame_start_stage2;
  reg can_frame_end_stage1, can_frame_end_stage2, can_frame_end_stage3;
  reg [31:0] current_timestamp_stage1, current_timestamp_stage2;
  reg timestamp_capture_stage1, timestamp_capture_stage2;
  reg valid_stage1, valid_stage2, valid_stage3;
  
  // 流水线控制信号
  wire timestamp_update_needed;
  
  // 常量定义
  localparam PRESCALER = 1000; // 微秒分辨率
  
  // 流水线阶段 1: 时基生成与输入同步
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prescaler_counter <= 16'd0;
      increment_timestamp <= 1'b0;
      can_frame_start_stage1 <= 1'b0;
      can_frame_end_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      // 预分频计数器逻辑
      if (prescaler_counter >= PRESCALER - 1) begin
        prescaler_counter <= 16'd0;
        increment_timestamp <= 1'b1;
      end else begin
        prescaler_counter <= prescaler_counter + 16'd1;
        increment_timestamp <= 1'b0;
      end
      
      // 同步输入信号到流水线
      can_frame_start_stage1 <= can_frame_start;
      can_frame_end_stage1 <= can_frame_end;
      valid_stage1 <= can_frame_end;
    end
  end
  
  // 流水线阶段 2: 时间戳更新和帧开始检测
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_timestamp <= 32'd0;
      current_timestamp_stage1 <= 32'd0;
      can_frame_start_stage2 <= 1'b0;
      can_frame_end_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
      timestamp_capture_stage1 <= 1'b0;
    end else begin
      // 时间戳更新逻辑
      if (increment_timestamp) begin
        current_timestamp <= current_timestamp + 32'd1;
      end
      
      // 传递当前时间戳到下一级
      current_timestamp_stage1 <= current_timestamp;
      
      // 检测帧开始并设置捕获标志
      can_frame_start_stage2 <= can_frame_start_stage1;
      timestamp_capture_stage1 <= can_frame_start_stage1;
      
      // 传递控制信号
      can_frame_end_stage2 <= can_frame_end_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 流水线阶段 3: 时间戳捕获与处理
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_timestamp <= 32'd0;
      current_timestamp_stage2 <= 32'd0;
      timestamp_capture_stage2 <= 1'b0;
      can_frame_end_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else begin
      // 传递中间时间戳
      current_timestamp_stage2 <= current_timestamp_stage1;
      
      // 帧时间戳捕获逻辑，使用前一级的时间戳以减少关键路径
      if (timestamp_capture_stage1) begin
        frame_timestamp <= current_timestamp_stage1;
      end
      
      // 传递捕获控制信号
      timestamp_capture_stage2 <= timestamp_capture_stage1;
      
      // 传递帧结束和有效信号
      can_frame_end_stage3 <= can_frame_end_stage2;
      valid_stage3 <= valid_stage2;
    end
  end
  
  // 流水线阶段 4: 输出控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      timestamp_valid <= 1'b0;
    end else begin
      // 时间戳有效信号处理
      timestamp_valid <= valid_stage3;
    end
  end
  
  // 实现时间戳更新需求检测 - 用于可能的前递优化
  assign timestamp_update_needed = can_frame_start || can_frame_start_stage1;
  
endmodule