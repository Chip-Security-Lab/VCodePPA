//SystemVerilog
`timescale 1ns / 1ps

// 顶层模块 - 集成所有子模块并管理它们之间的连接
module can_ack_handler (
  input  wire clk,          // 系统时钟
  input  wire rst_n,        // 低电平有效复位信号
  input  wire can_rx,       // CAN接收信号
  input  wire can_tx,       // CAN发送信号（高电平为发送模式）
  input  wire in_ack_slot,  // 当前处于确认时隙指示
  input  wire in_ack_delim, // 当前处于确认分隔符指示
  output wire ack_error,    // 确认错误指示
  output wire can_ack_drive // 确认驱动信号
);

  // 内部连接信号
  wire transmit_mode;
  wire receive_mode;

  // 模式检测子模块
  can_mode_detector mode_detector_inst (
    .can_tx        (can_tx),
    .transmit_mode (transmit_mode),
    .receive_mode  (receive_mode)
  );

  // 确认驱动子模块 - 处理接收模式下的确认驱动
  can_ack_driver ack_driver_inst (
    .clk           (clk),
    .rst_n         (rst_n),
    .in_ack_slot   (in_ack_slot),
    .receive_mode  (receive_mode),
    .can_ack_drive (can_ack_drive)
  );

  // 确认监控子模块 - 处理发送模式下的确认检测
  can_ack_monitor ack_monitor_inst (
    .clk           (clk),
    .rst_n         (rst_n),
    .can_rx        (can_rx),
    .in_ack_slot   (in_ack_slot),
    .in_ack_delim  (in_ack_delim),
    .transmit_mode (transmit_mode),
    .ack_error     (ack_error)
  );

endmodule

// 模式检测子模块 - 确定当前操作模式
module can_mode_detector (
  input  wire can_tx,        // CAN发送信号
  output wire transmit_mode, // 发送模式指示
  output wire receive_mode   // 接收模式指示
);
  
  // CAN控制器操作模式确定
  assign transmit_mode = can_tx;      // 当can_tx为高时为发送模式
  assign receive_mode = ~can_tx;      // 当can_tx为低时为接收模式

endmodule

// 确认驱动子模块 - 处理接收模式下的确认发送
module can_ack_driver (
  input  wire clk,           // 系统时钟
  input  wire rst_n,         // 低电平有效复位信号
  input  wire in_ack_slot,   // 当前处于确认时隙指示
  input  wire receive_mode,  // 接收模式指示
  output reg  can_ack_drive  // 确认驱动信号
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_ack_drive <= 1'b0;
    end else begin
      // 在接收模式下的确认时隙期间驱动低电平（显性位）
      can_ack_drive <= in_ack_slot && receive_mode;
    end
  end

endmodule

// 确认监控子模块 - 处理发送模式下的确认检测
module can_ack_monitor (
  input  wire clk,           // 系统时钟
  input  wire rst_n,         // 低电平有效复位信号
  input  wire can_rx,        // CAN接收信号
  input  wire in_ack_slot,   // 当前处于确认时隙指示
  input  wire in_ack_delim,  // 当前处于确认分隔符指示
  input  wire transmit_mode, // 发送模式指示
  output reg  ack_error      // 确认错误指示
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack_error <= 1'b0;
    end else begin
      if (in_ack_slot && transmit_mode && can_rx) begin
        // 发送模式下，确认时隙内未检测到显性位（低电平）
        ack_error <= 1'b1;
      end else if (in_ack_delim) begin
        // 进入确认分隔符时重置错误标志，准备下一帧
        ack_error <= 1'b0;
      end
    end
  end

endmodule