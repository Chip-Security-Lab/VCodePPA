//SystemVerilog
// 顶层模块
module uart_flow_control (
  input wire clk, rst_n,
  input wire rx_in, clear_to_send,
  output wire tx_out, request_to_send,
  input wire [7:0] tx_data,
  input wire tx_valid,
  output wire tx_ready,
  output wire [7:0] rx_data,
  output wire rx_valid
);
  // 内部连接信号
  wire tx_start;
  wire tx_busy;
  wire tx_done;
  wire rx_ready;
  wire [7:0] rx_byte;
  wire frame_err;
  
  // 实例化发送控制子模块
  tx_flow_controller tx_controller (
    .clk(clk),
    .rst_n(rst_n),
    .tx_valid(tx_valid),
    .tx_busy(tx_busy),
    .clear_to_send(clear_to_send),
    .tx_start(tx_start),
    .tx_ready(tx_ready)
  );
  
  // 实例化接收控制子模块
  rx_flow_controller rx_controller (
    .clk(clk),
    .rst_n(rst_n),
    .rx_ready(rx_ready),
    .rx_byte(rx_byte),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .request_to_send(request_to_send)
  );
  
  // 实例化UART发送器
  uart_tx_engine tx_engine (
    .tx_out(tx_out),
    .tx_busy(tx_busy),
    .tx_done(tx_done),
    .tx_start(tx_start)
  );
  
  // 实例化UART接收器
  uart_rx_engine rx_engine (
    .rx_in(rx_in),
    .rx_ready(rx_ready),
    .rx_byte(rx_byte),
    .frame_err(frame_err)
  );
  
endmodule

// 发送流控制子模块
module tx_flow_controller (
  input wire clk, rst_n,
  input wire tx_valid,
  input wire tx_busy,
  input wire clear_to_send,
  output reg tx_start,
  output reg tx_ready
);
  // 内部信号
  wire tx_can_start;
  
  // 状态判断逻辑
  assign tx_can_start = tx_valid && !tx_busy && clear_to_send;
  
  // 状态更新逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_start <= 1'b0;
      tx_ready <= 1'b0;
    end else begin
      if (tx_can_start) begin
        tx_start <= 1'b1;
        tx_ready <= 1'b0;
      end else begin
        tx_start <= 1'b0;
        if (!tx_busy) begin
          tx_ready <= 1'b1;
        end
      end
    end
  end
endmodule

// 接收流控制子模块
module rx_flow_controller (
  input wire clk, rst_n,
  input wire rx_ready,
  input wire [7:0] rx_byte,
  output reg [7:0] rx_data,
  output reg rx_valid,
  output wire request_to_send
);
  // 内部信号
  wire rx_can_receive;
  wire rx_data_consumed;
  
  // 流控逻辑
  assign request_to_send = !rx_valid;
  assign rx_can_receive = rx_ready && !rx_valid;
  assign rx_data_consumed = rx_valid && !request_to_send;
  
  // 状态更新逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_valid <= 1'b0;
      rx_data <= 8'h00;
    end else begin
      if (rx_can_receive) begin
        rx_data <= rx_byte;
        rx_valid <= 1'b1;
      end else if (rx_data_consumed) begin
        rx_valid <= 1'b0;
      end
    end
  end
endmodule

// UART发送器引擎
module uart_tx_engine (
  output wire tx_out,
  output wire tx_busy,
  output wire tx_done,
  input wire tx_start
);
  // 简化的桩实现
  assign tx_out = 1'b1;         // 默认高电平(空闲状态)
  assign tx_busy = tx_start;    // 简单循环用于测试
  assign tx_done = !tx_busy && tx_start; // 当不忙且有启动信号时完成
endmodule

// UART接收器引擎
module uart_rx_engine (
  input wire rx_in,
  output wire rx_ready,
  output wire [7:0] rx_byte,
  output wire frame_err
);
  // 简化的桩实现
  assign rx_ready = rx_in;      // 简化实现
  assign rx_byte = 8'hAA;       // 测试数据
  assign frame_err = 1'b0;      // 无错误
endmodule