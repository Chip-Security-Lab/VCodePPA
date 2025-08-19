//SystemVerilog
module reset_event_counter (
  input wire clk,
  input wire reset_n,
  output reg [7:0] reset_count
);

  // 复位检测信号
  reg reset_n_prev;
  wire reset_event;

  // 记录上一个周期的复位信号状态，用于边沿检测
  always @(posedge clk) begin
    reset_n_prev <= reset_n;
  end

  // 复位信号的下降沿检测
  assign reset_event = reset_n_prev & ~reset_n;

  // 带状进位加法器信号
  wire [7:0] sum_with_cin0, sum_with_cin1;
  wire [3:0] carry_low;
  wire carry_select;
  
  // 低4位加法器（cin=0）
  assign {carry_low[0], sum_with_cin0[0]} = reset_count[0] + 1'b1;
  assign {carry_low[1], sum_with_cin0[1]} = reset_count[1] + carry_low[0];
  assign {carry_low[2], sum_with_cin0[2]} = reset_count[2] + carry_low[1];
  assign {carry_low[3], sum_with_cin0[3]} = reset_count[3] + carry_low[2];
  
  // 高4位加法器（假设cin=0）
  assign {carry_select, sum_with_cin0[7:4]} = reset_count[7:4] + 4'b0000;
  
  // 高4位加法器（假设cin=1）
  assign sum_with_cin1[7:4] = reset_count[7:4] + 4'b0001;
  
  // 根据低位进位选择高位结果
  wire [7:4] sum_high = carry_low[3] ? sum_with_cin1[7:4] : sum_with_cin0[7:4];
  
  // 组合最终结果
  wire [7:0] next_count = {sum_high, sum_with_cin0[3:0]};

  // 在检测到复位事件时递增计数器
  always @(posedge clk) begin
    if (reset_event)
      reset_count <= next_count;
  end

endmodule