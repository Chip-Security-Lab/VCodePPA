//SystemVerilog - IEEE 1364-2005
`timescale 1ns / 1ps
module reset_distribution_monitor (
  input wire clk,
  input wire global_reset,
  input wire [7:0] local_resets,
  output reg distribution_error
);
  // 流水线阶段寄存器
  reg global_reset_prev;
  reg global_reset_edge_stage1, global_reset_edge_stage2;
  reg [2:0] check_state;
  reg [2:0] check_state_stage1, check_state_stage2;
  reg [7:0] local_resets_stage1, local_resets_stage2;
  
  // 阶段控制信号
  reg valid_stage1, valid_stage2;
  
  // 第0阶段：边沿检测和状态保持
  wire global_reset_edge;
  
  // 捕获全局复位上升沿
  always @(posedge clk) begin
    global_reset_prev <= global_reset;
  end
  
  assign global_reset_edge = global_reset && !global_reset_prev;
  
  // 第1阶段：前缀加法器-前半部分
  wire [2:0] p_stage1;
  wire [2:0] g_stage1;
  wire [1:0] pp_stage1;
  
  // 第1阶段流水线寄存器
  always @(posedge clk) begin
    if (global_reset) begin
      check_state_stage1 <= 3'd0;
      global_reset_edge_stage1 <= 1'b0;
      local_resets_stage1 <= 8'h00;
      valid_stage1 <= 1'b0;
    end else begin
      check_state_stage1 <= check_state;
      global_reset_edge_stage1 <= global_reset_edge;
      local_resets_stage1 <= local_resets;
      valid_stage1 <= 1'b1;
    end
  end
  
  // 第1阶段组合逻辑
  assign p_stage1 = check_state_stage1 ^ 3'd1;  // Propagate = a XOR b
  assign g_stage1 = check_state_stage1 & 3'd1;  // Generate = a AND b
  
  // Level 1 prefix computation
  assign pp_stage1[0] = p_stage1[0] & p_stage1[1];
  
  // 第2阶段：前缀加法器-后半部分
  reg [2:0] p_stage2;
  reg [2:0] g_stage2_in;
  wire [2:0] g_stage2_out;
  reg [1:0] pp_stage2;
  wire [2:0] c_stage2;
  wire [2:0] next_state;
  
  // 第2阶段流水线寄存器
  always @(posedge clk) begin
    if (global_reset) begin
      p_stage2 <= 3'd0;
      g_stage2_in <= 3'd0;
      pp_stage2 <= 2'd0;
      check_state_stage2 <= 3'd0;
      global_reset_edge_stage2 <= 1'b0;
      local_resets_stage2 <= 8'h00;
      valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
      p_stage2 <= p_stage1;
      g_stage2_in[0] <= g_stage1[0];
      g_stage2_in[1] <= g_stage1[1];
      g_stage2_in[2] <= g_stage1[2];
      pp_stage2 <= pp_stage1;
      check_state_stage2 <= check_state_stage1;
      global_reset_edge_stage2 <= global_reset_edge_stage1;
      local_resets_stage2 <= local_resets_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 第2阶段组合逻辑 - 完成前缀加法器计算
  // Level 1 (从阶段1传递过来的部分结果)
  assign g_stage2_out[0] = g_stage2_in[0];
  assign g_stage2_out[1] = g_stage2_in[1] | (p_stage2[1] & g_stage2_in[0]);
  assign g_stage2_out[2] = g_stage2_in[2];
  
  // Level 2
  wire [2:0] g_stage2_final;
  assign g_stage2_final[0] = g_stage2_out[0];
  assign g_stage2_final[1] = g_stage2_out[1];
  assign g_stage2_final[2] = g_stage2_in[2] | (p_stage2[2] & g_stage2_out[1]);
  
  // Carry computation
  assign c_stage2[0] = 1'b0;  // No initial carry
  assign c_stage2[1] = g_stage2_in[0];
  assign c_stage2[2] = g_stage2_out[1];
  
  // Final sum
  assign next_state = p_stage2 ^ {c_stage2[2:1], 1'b0};
  
  // 错误检测逻辑
  wire error_condition = valid_stage2 && (check_state_stage2 == 3'd3) && (local_resets_stage2 != 8'hFF);
  
  // 状态更新和错误检测
  always @(posedge clk) begin
    if (global_reset_edge)
      check_state <= 3'd0;
    else if (valid_stage2 && check_state < 3'd4)
      check_state <= next_state;
      
    if (error_condition)
      distribution_error <= 1'b1;
    else if (global_reset_edge)
      distribution_error <= 1'b0;
  end
endmodule