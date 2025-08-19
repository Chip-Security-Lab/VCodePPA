//SystemVerilog
// 顶层模块
module can_error_recovery(
  input wire clk, rst_n,
  input wire error_detected, bus_off_state,
  input wire [7:0] tx_error_count, rx_error_count,
  output reg [1:0] error_state,
  output reg error_passive_mode, recovery_in_progress
);
  // 状态参数定义
  localparam [1:0] ERROR_ACTIVE = 2'd0, 
                  ERROR_PASSIVE = 2'd1, 
                  BUS_OFF = 2'd2;
                  
  reg [9:0] recovery_counter;
  wire tx_error_threshold_128, rx_error_threshold_128, tx_error_threshold_255;
  wire bus_off_condition, error_passive_condition;
  
  // 实例化错误阈值监测子模块
  error_threshold_detector threshold_detector(
    .tx_error_count(tx_error_count),
    .rx_error_count(rx_error_count),
    .tx_error_threshold_128(tx_error_threshold_128),
    .rx_error_threshold_128(rx_error_threshold_128),
    .tx_error_threshold_255(tx_error_threshold_255)
  );
  
  // 实例化状态条件计算子模块
  error_condition_analyzer condition_analyzer(
    .tx_error_threshold_255(tx_error_threshold_255),
    .tx_error_threshold_128(tx_error_threshold_128),
    .rx_error_threshold_128(rx_error_threshold_128),
    .bus_off_state(bus_off_state),
    .bus_off_condition(bus_off_condition),
    .error_passive_condition(error_passive_condition)
  );
  
  // 实例化状态更新控制子模块
  error_state_controller state_controller(
    .clk(clk),
    .rst_n(rst_n),
    .bus_off_condition(bus_off_condition),
    .error_passive_condition(error_passive_condition),
    .recovery_counter(recovery_counter),
    .error_state(error_state),
    .error_passive_mode(error_passive_mode),
    .recovery_in_progress(recovery_in_progress)
  );
  
  // 实例化恢复计数器控制子模块
  recovery_counter_controller recovery_ctrl(
    .clk(clk),
    .rst_n(rst_n),
    .recovery_in_progress(recovery_in_progress),
    .recovery_counter(recovery_counter)
  );
endmodule

// 错误阈值监测子模块
module error_threshold_detector(
  input wire [7:0] tx_error_count, rx_error_count,
  output wire tx_error_threshold_128, rx_error_threshold_128, tx_error_threshold_255
);
  // 优化的比较逻辑 - 使用独立的阈值信号
  assign tx_error_threshold_128 = (tx_error_count >= 8'd128);
  assign rx_error_threshold_128 = (rx_error_count >= 8'd128);
  assign tx_error_threshold_255 = (tx_error_count >= 8'd255);
endmodule

// 状态条件计算子模块
module error_condition_analyzer(
  input wire tx_error_threshold_255, tx_error_threshold_128, rx_error_threshold_128,
  input wire bus_off_state,
  output wire bus_off_condition, error_passive_condition
);
  // 组合逻辑用于确定状态条件
  assign bus_off_condition = tx_error_threshold_255 || bus_off_state;
  assign error_passive_condition = tx_error_threshold_128 || rx_error_threshold_128;
endmodule

// 状态更新控制子模块
module error_state_controller(
  input wire clk, rst_n,
  input wire bus_off_condition, error_passive_condition,
  input wire [9:0] recovery_counter,
  output reg [1:0] error_state,
  output reg error_passive_mode, recovery_in_progress
);
  // 状态参数定义
  localparam [1:0] ERROR_ACTIVE = 2'd0, 
                  ERROR_PASSIVE = 2'd1, 
                  BUS_OFF = 2'd2;
                  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_state <= ERROR_ACTIVE;
      error_passive_mode <= 1'b0;
      recovery_in_progress <= 1'b0;
    end else begin
      // 优化的状态确定 - 使用优先级编码方式
      if (bus_off_condition) begin
        error_state <= BUS_OFF;
        error_passive_mode <= 1'b1;
        recovery_in_progress <= 1'b1;
      end else if (error_passive_condition) begin
        error_state <= ERROR_PASSIVE;
        error_passive_mode <= 1'b1;
        recovery_in_progress <= 1'b0;
      end else begin
        error_state <= ERROR_ACTIVE;
        error_passive_mode <= 1'b0;
        recovery_in_progress <= 1'b0;
      end
    end
  end
endmodule

// 恢复计数器控制子模块
module recovery_counter_controller(
  input wire clk, rst_n,
  input wire recovery_in_progress,
  output reg [9:0] recovery_counter
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      recovery_counter <= 10'd0;
    end else begin
      // 总线关闭恢复逻辑
      if (recovery_in_progress) begin
        if (recovery_counter >= 10'd127) begin
          recovery_counter <= 10'd0;
        end else begin
          recovery_counter <= recovery_counter + 10'd1;
        end
      end else begin
        recovery_counter <= 10'd0;
      end
    end
  end
endmodule