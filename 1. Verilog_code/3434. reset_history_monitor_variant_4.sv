//SystemVerilog
module reset_history_monitor (
  input wire clk,
  input wire reset_in,
  input wire req,         // 替代原来的clear信号，作为请求信号
  output reg ack,         // 新增的应答信号
  output reg [7:0] reset_history
);
  reg reset_in_d;
  wire reset_edge_detected;
  reg req_d;              // 请求信号的延迟寄存器
  reg processing;         // 处理状态标志
  
  // 检测reset_in的上升沿
  assign reset_edge_detected = reset_in & ~reset_in_d;
  
  // 实现请求-应答握手协议的状态机
  always @(posedge clk) begin
    // 将延迟寄存器更新放在逻辑开始，优化时序路径
    reset_in_d <= reset_in;
    req_d <= req;
    
    // 默认复位应答信号
    ack <= 1'b0;
    
    // 请求-应答握手协议实现
    if (req & ~req_d & ~processing) begin
      // 检测到新请求
      processing <= 1'b1;
      
      // 处理数据 - 清除历史或记录复位边沿
      if (reset_edge_detected)
        reset_history <= {reset_history[6:0], 1'b1};
      else
        reset_history <= 8'h00; // 清除历史
        
      // 发送应答信号
      ack <= 1'b1;
    end
    else if (processing & ~req) begin
      // 请求结束，完成处理
      processing <= 1'b0;
    end
    else if (~processing & reset_edge_detected) begin
      // 无请求情况下仍然监控复位信号
      reset_history <= {reset_history[6:0], 1'b1};
    end
  end
endmodule