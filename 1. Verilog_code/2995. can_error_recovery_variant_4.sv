//SystemVerilog
module can_error_recovery(
  input wire clk, rst_n,
  input wire error_detected, bus_off_state,
  input wire [7:0] tx_error_count, rx_error_count,
  output reg [1:0] error_state,
  output reg error_passive_mode, recovery_in_progress
);
  localparam ERROR_ACTIVE = 2'b00, ERROR_PASSIVE = 2'b01, BUS_OFF = 2'b10;
  
  reg [9:0] recovery_counter;
  reg [3:0] state_index;
  reg [4:0] state_table [0:7]; // [error_state, error_passive_mode, recovery_in_progress, update_counter]
  wire update_counter;
  wire [1:0] next_error_state;
  wire next_error_passive_mode;
  wire next_recovery_in_progress;
  
  // 状态表初始化，使用索引进行查询
  initial begin
    // 格式: {error_state, error_passive_mode, recovery_in_progress, update_counter}
    // Case 0: 正常状态 - ERROR_ACTIVE
    state_table[0] = {ERROR_ACTIVE, 1'b0, 1'b0, 1'b0};
    
    // Case 1: 错误被动状态 - ERROR_PASSIVE
    state_table[1] = {ERROR_PASSIVE, 1'b1, 1'b0, 1'b0};
    
    // Case 2: 总线关闭状态 - BUS_OFF，开始恢复
    state_table[2] = {BUS_OFF, 1'b1, 1'b1, 1'b1};
    
    // Case 3: 恢复进行中，未达到门限
    state_table[3] = {2'bxx, 1'bx, 1'b1, 1'b1};
    
    // Case 4: 恢复完成
    state_table[4] = {2'bxx, 1'bx, 1'b0, 1'b0};
    
    // 其余状态保留
    state_table[5] = 5'b0;
    state_table[6] = 5'b0;
    state_table[7] = 5'b0;
  end
  
  // 生成查找表索引 - 组合逻辑
  always @(*) begin
    if (tx_error_count >= 8'd255 || bus_off_state)
      state_index = 4'd2; // BUS_OFF状态
    else if (tx_error_count >= 8'd128 || rx_error_count >= 8'd128)
      state_index = 4'd1; // ERROR_PASSIVE状态
    else if (!recovery_in_progress)
      state_index = 4'd0; // ERROR_ACTIVE状态
    else if (recovery_in_progress && recovery_counter < 10'd128)
      state_index = 4'd3; // 恢复进行中
    else
      state_index = 4'd4; // 恢复完成
  end
  
  // 从状态表提取控制信号 - 组合逻辑
  assign next_error_state = (state_table[state_index][1:0] != 2'bxx) ? 
                            state_table[state_index][4:3] : error_state;
  
  assign next_error_passive_mode = (state_table[state_index][2] != 1'bx) ? 
                                  state_table[state_index][2] : error_passive_mode;
  
  assign next_recovery_in_progress = state_table[state_index][1];
  
  assign update_counter = state_table[state_index][0];
  
  // 错误状态寄存器更新 - 时序逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_state <= ERROR_ACTIVE;
    end else begin
      error_state <= next_error_state;
    end
  end
  
  // 错误被动模式寄存器更新 - 时序逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_passive_mode <= 1'b0;
    end else begin
      error_passive_mode <= next_error_passive_mode;
    end
  end
  
  // 恢复进行中标志寄存器更新 - 时序逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      recovery_in_progress <= 1'b0;
    end else begin
      recovery_in_progress <= next_recovery_in_progress;
    end
  end
  
  // 恢复计数器逻辑 - 时序逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      recovery_counter <= 10'd0;
    end else begin
      if (!recovery_in_progress && next_recovery_in_progress) 
        recovery_counter <= 10'd1; // 开始恢复过程
      else if (recovery_in_progress && update_counter)
        recovery_counter <= recovery_counter + 10'd1; // 增加计数器
      else if (!next_recovery_in_progress)
        recovery_counter <= 10'd0; // 重置计数器
    end
  end
endmodule