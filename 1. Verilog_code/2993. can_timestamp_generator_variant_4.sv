//SystemVerilog
module can_timestamp_generator(
  input wire clk, rst_n,
  input wire can_rx_edge, can_frame_start, can_frame_end,
  output reg [31:0] current_timestamp,
  output reg [31:0] frame_timestamp,
  output reg timestamp_valid
);
  // 定义流水线阶段信号
  reg [15:0] prescaler_count;
  reg prescaler_overflow_pipe1;
  reg prescaler_overflow_pipe2;
  
  reg [31:0] timestamp_counter;
  reg [31:0] timestamp_pipe1;
  reg [31:0] timestamp_pipe2;
  reg [31:0] timestamp_pipe3;
  
  reg can_frame_start_pipe1, can_frame_start_pipe2;
  reg can_frame_end_pipe1, can_frame_end_pipe2, can_frame_end_pipe3;
  
  reg [31:0] frame_timestamp_pipe1;
  reg [31:0] frame_timestamp_pipe2;
  
  localparam PRESCALER = 1000; // For microsecond resolution
  
  // 第一级流水线：预分频计数与溢出检测
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prescaler_count <= 16'h0;
      prescaler_overflow_pipe1 <= 1'b0;
      can_frame_start_pipe1 <= 1'b0;
      can_frame_end_pipe1 <= 1'b0;
    end else begin
      // 事件信号流水线
      can_frame_start_pipe1 <= can_frame_start;
      can_frame_end_pipe1 <= can_frame_end;
      
      // 切分预分频计数与溢出检测逻辑
      if (prescaler_count >= PRESCALER - 1) begin
        prescaler_count <= 16'h0;
        prescaler_overflow_pipe1 <= 1'b1;
      end else begin
        prescaler_count <= prescaler_count + 16'h1;
        prescaler_overflow_pipe1 <= 1'b0;
      end
    end
  end
  
  // 第二级流水线：时间戳计数器更新和信号传递
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      timestamp_counter <= 32'h0;
      timestamp_pipe1 <= 32'h0;
      prescaler_overflow_pipe2 <= 1'b0;
      can_frame_start_pipe2 <= 1'b0;
      can_frame_end_pipe2 <= 1'b0;
    end else begin
      // 时间戳计数器更新
      if (prescaler_overflow_pipe1) begin
        timestamp_counter <= timestamp_counter + 32'h1;
      end
      
      // 时间戳值流水线传递
      timestamp_pipe1 <= timestamp_counter;
      
      // 控制信号流水线传递
      prescaler_overflow_pipe2 <= prescaler_overflow_pipe1;
      can_frame_start_pipe2 <= can_frame_start_pipe1;
      can_frame_end_pipe2 <= can_frame_end_pipe1;
    end
  end
  
  // 第三级流水线：帧时间戳捕获
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      timestamp_pipe2 <= 32'h0;
      frame_timestamp_pipe1 <= 32'h0;
      can_frame_end_pipe3 <= 1'b0;
      timestamp_pipe3 <= 32'h0;
    end else begin
      // 时间戳传递
      timestamp_pipe2 <= timestamp_pipe1;
      timestamp_pipe3 <= timestamp_pipe2;
      
      // 帧开始时捕获时间戳
      if (can_frame_start_pipe2) begin
        frame_timestamp_pipe1 <= timestamp_pipe1;
      end
      
      // 控制信号传递
      can_frame_end_pipe3 <= can_frame_end_pipe2;
    end
  end
  
  // 第四级流水线：输出寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_timestamp <= 32'h0;
      frame_timestamp <= 32'h0;
      frame_timestamp_pipe2 <= 32'h0;
      timestamp_valid <= 1'b0;
    end else begin
      // 更新当前时间戳输出
      current_timestamp <= timestamp_pipe3;
      
      // 帧时间戳流水线
      frame_timestamp_pipe2 <= frame_timestamp_pipe1;
      
      // 帧时间戳输出
      if (can_frame_start_pipe2) begin
        frame_timestamp <= timestamp_pipe2;
      end else if (|frame_timestamp_pipe2) begin
        frame_timestamp <= frame_timestamp_pipe2;
      end
      
      // 时间戳有效信号处理
      if (can_frame_end_pipe3) begin
        timestamp_valid <= 1'b1;
      end else begin
        timestamp_valid <= 1'b0;
      end
    end
  end
endmodule