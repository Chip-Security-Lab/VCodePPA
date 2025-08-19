//SystemVerilog

// 顶层模块
module reset_distribution_monitor (
  input wire clk,
  input wire global_reset,
  input wire [7:0] local_resets,
  output reg distribution_error
);
  wire [2:0] check_state;
  wire [2:0] next_state;
  reg global_reset_d1; // 第一级寄存器
  reg global_reset_d2; // 第二级寄存器
  wire global_reset_edge = global_reset_d1;
  
  // 优化：直接在顶层进行global_reset的采样，避免子模块的输入延迟
  always @(posedge clk) begin
    global_reset_d1 <= global_reset;
    global_reset_d2 <= global_reset_d1;
  end
  
  // 子模块实例化
  manchester_counter u_manchester_counter (
    .current_state(check_state),
    .next_state(next_state)
  );
  
  state_controller u_state_controller (
    .clk(clk),
    .global_reset(global_reset),
    .global_reset_d(global_reset_d1),
    .next_state(next_state),
    .check_state(check_state)
  );
  
  error_monitor u_error_monitor (
    .clk(clk),
    .global_reset(global_reset),
    .global_reset_d(global_reset_d1),
    .check_state(check_state),
    .local_resets(local_resets),
    .distribution_error(distribution_error)
  );
  
endmodule

// 曼彻斯特进位链计数器子模块
module manchester_counter (
  input wire [2:0] current_state,
  output reg [2:0] next_state
);
  // 曼彻斯特进位链加法器信号
  wire [2:0] p; // 传播信号
  wire [2:0] g; // 生成信号
  wire [3:0] c; // 进位信号
  
  // 计算传播和生成信号
  assign p[0] = current_state[0];
  assign g[0] = 1'b0;
  assign p[1] = current_state[1];
  assign g[1] = current_state[1] & current_state[0];
  assign p[2] = current_state[2];
  assign g[2] = current_state[2] & (current_state[1] & current_state[0]);
  
  // 曼彻斯特进位链
  assign c[0] = 1'b1; // 加1操作的初始进位
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  
  // 优化：将纯组合逻辑结果用寄存器缓存，减少后级逻辑延迟
  always @(*) begin
    next_state[0] = current_state[0] ^ c[0];
    next_state[1] = current_state[1] ^ c[1];
    next_state[2] = current_state[2] ^ c[2];
  end
  
endmodule

// 状态控制器子模块
module state_controller (
  input wire clk,
  input wire global_reset,
  input wire global_reset_d,
  input wire [2:0] next_state,
  output reg [2:0] check_state
);
  reg reset_detected;
  
  // 优化：分离复位检测逻辑
  always @(posedge clk) begin
    reset_detected <= global_reset && !global_reset_d;
  end
  
  // 优化：简化状态更新逻辑，降低关键路径延迟
  always @(posedge clk) begin
    if (reset_detected)
      check_state <= 3'd0;
    else if (check_state < 3'd4)
      check_state <= next_state;
  end
  
endmodule

// 错误监控子模块
module error_monitor (
  input wire clk,
  input wire global_reset,
  input wire global_reset_d,
  input wire [2:0] check_state,
  input wire [7:0] local_resets,
  output reg distribution_error
);
  reg state_is_3;
  reg resets_not_ready;
  reg reset_detected;
  
  // 优化：分解关键路径，将组合逻辑移入寄存器
  always @(posedge clk) begin
    state_is_3 <= (check_state == 3'd3);
    resets_not_ready <= (local_resets != 8'hFF);
    reset_detected <= global_reset && !global_reset_d;
  end
  
  // 优化：使用预计算的条件，减少关键路径延迟
  always @(posedge clk) begin
    if (state_is_3 && resets_not_ready)
      distribution_error <= 1'b1;
    else if (reset_detected)
      distribution_error <= 1'b0;
  end
  
endmodule