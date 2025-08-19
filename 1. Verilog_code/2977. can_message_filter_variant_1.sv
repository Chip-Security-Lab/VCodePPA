//SystemVerilog
// 顶层模块
module can_message_filter (
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [10:0] filter_masks [0:3],
  input wire [10:0] filter_values [0:3],
  input wire [3:0] filter_enable,
  output wire frame_accepted
);
  
  // 内部连线
  wire [3:0] match_signals;
  
  // 实例化ID匹配检测模块
  id_matcher id_matcher_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx_id(rx_id),
    .id_valid(id_valid),
    .filter_masks(filter_masks),
    .filter_values(filter_values),
    .filter_enable(filter_enable),
    .match_signals(match_signals)
  );
  
  // 实例化判决模块
  match_decision match_decision_inst (
    .clk(clk),
    .rst_n(rst_n),
    .match_signals(match_signals),
    .id_valid(id_valid),
    .frame_accepted(frame_accepted)
  );
  
endmodule

// ID匹配检测模块 - 负责比较接收到的ID与过滤器
module id_matcher (
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [10:0] filter_masks [0:3],
  input wire [10:0] filter_values [0:3],
  input wire [3:0] filter_enable,
  output reg [3:0] match_signals
);
  
  // 预计算匹配结果以减少关键路径延迟
  reg [3:0] match_results;
  reg [10:0] masked_rx_id [0:3];
  
  integer i;
  
  // 组合逻辑预计算匹配结果
  always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
      masked_rx_id[i] = rx_id & filter_masks[i];
      match_results[i] = filter_enable[i] && (masked_rx_id[i] == filter_values[i]);
    end
  end
  
  // 寄存器过程，捕获最终结果
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      match_signals <= 4'b0000;
    end else if (id_valid) begin
      match_signals <= match_results;
    end
  end
  
endmodule

// 匹配判决模块 - 根据匹配信号确定是否接受帧
module match_decision (
  input wire clk, rst_n,
  input wire [3:0] match_signals,
  input wire id_valid,
  output reg frame_accepted
);
  
  // 优化匹配判断逻辑，通过一步式 OR 运算来减少延迟
  wire any_match;
  assign any_match = |match_signals;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_accepted <= 1'b0;
    end else if (id_valid) begin
      frame_accepted <= any_match;
    end
  end
  
endmodule