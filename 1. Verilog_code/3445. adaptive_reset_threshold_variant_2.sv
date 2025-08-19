//SystemVerilog
module adaptive_reset_threshold (
  input wire clk,
  input wire [7:0] signal_level,
  input wire [7:0] base_threshold,
  input wire [3:0] hysteresis,
  input wire req,        // 请求信号
  output reg ack,        // 应答信号
  output reg reset_trigger
);
  reg [7:0] current_threshold;
  reg processing;
  reg req_d;
  wire req_edge;
  wire [7:0] high_threshold;
  
  // 流水线寄存器
  reg [7:0] signal_level_r;
  reg [7:0] current_threshold_r;
  reg reset_trigger_r;
  reg signal_lt_threshold;  // 信号小于阈值的比较结果寄存器
  reg signal_gt_threshold;  // 信号大于阈值的比较结果寄存器
  reg [1:0] processing_stage;  // 处理阶段计数器
  
  // 计算高阈值 - 添加寄存器减少组合逻辑路径
  reg [7:0] high_threshold_r;
  always @(posedge clk) begin
    high_threshold_r <= base_threshold + hysteresis;
  end
  assign high_threshold = high_threshold_r;
  
  // 检测请求上升沿
  always @(posedge clk) begin
    req_d <= req;
  end
  
  // 边沿检测
  assign req_edge = req && !req_d;
  
  // 第一级流水线：寄存信号和阈值，进行比较操作
  always @(posedge clk) begin
    signal_level_r <= signal_level;
    current_threshold_r <= current_threshold;
    reset_trigger_r <= reset_trigger;
    
    // 预计算比较结果，切割关键路径
    signal_lt_threshold <= signal_level < current_threshold;
    signal_gt_threshold <= signal_level > current_threshold;
  end
  
  // 主状态机逻辑 - 流水线化处理
  always @(posedge clk) begin
    // 默认保持ack不变
    
    case (processing_stage)
      2'b00: begin  // 空闲状态
        if (req_edge) begin
          processing <= 1'b1;
          processing_stage <= 2'b01;  // 进入第一阶段
          ack <= 1'b0;
        end
      end
      
      2'b01: begin  // 第一阶段：使用预计算的比较结果
        // 更新reset_trigger
        case (reset_trigger_r)
          1'b0: reset_trigger <= signal_lt_threshold ? 1'b1 : 1'b0;
          1'b1: reset_trigger <= signal_gt_threshold ? 1'b0 : 1'b1;
        endcase
        processing_stage <= 2'b10;  // 进入第二阶段
      end
      
      2'b10: begin  // 第二阶段：更新阈值
        // 优化的阈值更新逻辑
        if ((signal_lt_threshold && !reset_trigger_r) || 
            (signal_gt_threshold && reset_trigger_r)) begin
          current_threshold <= reset_trigger ? base_threshold : high_threshold;
        end
        
        // 处理完成，发送应答
        ack <= 1'b1;
        processing_stage <= 2'b11;  // 进入等待结束阶段
      end
      
      2'b11: begin  // 等待请求撤销
        if (!req) begin
          // 请求已撤销，重置处理状态
          processing <= 1'b0;
          ack <= 1'b0;
          processing_stage <= 2'b00;  // 回到空闲状态
        end
      end
    endcase
  end
  
  // 初始值设置
  initial begin
    processing = 1'b0;
    ack = 1'b0;
    req_d = 1'b0;
    current_threshold = base_threshold;
    reset_trigger = 1'b0;
    processing_stage = 2'b00;
    signal_level_r = 8'h00;
    current_threshold_r = 8'h00;
    reset_trigger_r = 1'b0;
    signal_lt_threshold = 1'b0;
    signal_gt_threshold = 1'b0;
    high_threshold_r = 8'h00;
  end
endmodule