//SystemVerilog
module window_reset_monitor #(
  parameter MIN_WINDOW = 4,
  parameter MAX_WINDOW = 12
) (
  input wire clk,
  input wire reset_pulse,
  output reg valid_reset
);
  // 定义流水线级数
  localparam PIPE_STAGES = 3;
  
  // 流水线阶段1：检测复位信号，启动计数
  reg reset_pulse_stage1;
  reg reset_active_stage1;
  reg [$clog2(MAX_WINDOW):0] window_counter_stage1;
  
  // 流水线阶段2：计数和复位条件判断
  reg reset_pulse_stage2;
  reg reset_active_stage2;
  reg [$clog2(MAX_WINDOW):0] window_counter_stage2;
  reg counter_done_stage2;
  
  // 流水线阶段3：验证复位窗口并生成输出
  reg reset_active_stage3;
  reg counter_done_stage3;
  reg [$clog2(MAX_WINDOW):0] window_counter_stage3;
  reg valid_window_stage3;
  
  // 流水线控制信号
  reg [PIPE_STAGES-1:0] valid_pipe;
  
  // 中间变量，用于简化条件逻辑
  reg reset_edge_detected;
  reg window_counting_active;
  reg reset_deasserted;
  reg counter_in_valid_range;
  reg pipeline_valid;
  reg need_pipeline_flush;
  
  // 阶段1: 检测复位并初始化计数
  always @(posedge clk) begin
    // 注册输入
    reset_pulse_stage1 <= reset_pulse;
    
    // 检测复位上升沿
    reset_edge_detected = reset_pulse && !reset_active_stage1;
    
    // 复位计数状态
    window_counting_active = reset_active_stage1;
    
    if (reset_edge_detected) begin
      // 新的复位上升沿
      reset_active_stage1 <= 1'b1;
      window_counter_stage1 <= 0;
      valid_pipe[0] <= 1'b1;
    end 
    else if (window_counting_active) begin
      // 复位窗口计数
      window_counter_stage1 <= window_counter_stage1 + 1;
      
      // 检测复位下降沿
      reset_deasserted = !reset_pulse_stage1;
      
      if (reset_deasserted) begin
        reset_active_stage1 <= 1'b0;
        counter_done_stage2 <= 1'b1;
      end
    end
  end
  
  // 阶段2: 计数和复位条件判断
  always @(posedge clk) begin
    // 数据前移
    reset_pulse_stage2 <= reset_pulse_stage1;
    reset_active_stage2 <= reset_active_stage1;
    window_counter_stage2 <= window_counter_stage1;
    valid_pipe[1] <= valid_pipe[0];
    
    // 检测计数完成和复位失效
    reset_deasserted = !reset_pulse_stage2;
    
    if (counter_done_stage2 && reset_deasserted) begin
      counter_done_stage2 <= 1'b0;
      counter_done_stage3 <= 1'b1;
    end
  end
  
  // 阶段3: 验证窗口并生成输出
  always @(posedge clk) begin
    // 数据前移
    reset_active_stage3 <= reset_active_stage2;
    window_counter_stage3 <= window_counter_stage2;
    valid_pipe[2] <= valid_pipe[1];
    
    if (counter_done_stage3) begin
      counter_done_stage3 <= 1'b0;
      
      // 验证窗口范围 - 分成两个简单条件
      counter_in_valid_range = 0;
      if (window_counter_stage3 >= MIN_WINDOW) begin
        if (window_counter_stage3 <= MAX_WINDOW) begin
          counter_in_valid_range = 1;
        end
      end
      
      valid_window_stage3 <= counter_in_valid_range;
      
      // 检查管道有效性
      pipeline_valid = valid_pipe[2];
      
      if (pipeline_valid) begin
        valid_reset <= valid_window_stage3;
      end
    end
  end
  
  // 前递逻辑，处理连续复位信号
  always @(posedge clk) begin
    // 新复位事件进入时旧复位尚未结束
    need_pipeline_flush = reset_pulse && !reset_active_stage1 && reset_active_stage3;
    
    if (need_pipeline_flush) begin
      // 刷新流水线
      valid_pipe <= 3'b0;
      reset_active_stage2 <= 1'b0;
      reset_active_stage3 <= 1'b0;
      counter_done_stage2 <= 1'b0;
      counter_done_stage3 <= 1'b0;
    end
  end
endmodule