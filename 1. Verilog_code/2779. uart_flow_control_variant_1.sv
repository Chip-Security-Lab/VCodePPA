//SystemVerilog
module uart_flow_control (
  input wire clk, rst_n,
  input wire rx_in, clear_to_send,
  output wire tx_out, request_to_send,
  input wire [7:0] tx_data,
  input wire tx_valid,
  output reg tx_ready,
  output reg [7:0] rx_data,
  output reg rx_valid
);
  reg tx_start;
  wire tx_busy;
  wire tx_done;
  wire rx_ready;
  wire [7:0] rx_byte;
  wire frame_err;
  
  // 优化流控制逻辑
  wire rx_buffer_full = rx_valid || rx_ready;
  reg request_to_send_reg;
  
  assign request_to_send = request_to_send_reg;
  
  // 优化控制信号计算
  wire can_transmit = clear_to_send && !tx_busy;
  wire next_tx_start = tx_valid && can_transmit;
  wire next_tx_ready = can_transmit;
  
  // 简化RX有效信号逻辑
  wire rx_data_available = rx_ready && !rx_valid;
  wire rx_data_consumed = rx_valid && !request_to_send_reg;
  
  // 寄存器更新逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_start <= 1'b0;
      tx_ready <= 1'b0;
      rx_valid <= 1'b0;
      rx_data <= 8'h0;
      request_to_send_reg <= 1'b1; // 重置时允许接收数据
    end else begin
      // 优化的TX控制逻辑 - 合并条件
      tx_start <= next_tx_start;
      tx_ready <= next_tx_ready;
      
      // 优化的RX控制逻辑 - 使用单一条件更新
      if (rx_data_available) begin
        rx_data <= rx_byte;
        rx_valid <= 1'b1;
      end else if (rx_data_consumed) begin
        rx_valid <= 1'b0;
      end
      
      // 优化的流控制信号更新
      request_to_send_reg <= !rx_buffer_full;
    end
  end
  
  // uart_tx模块桩
  assign tx_out = 1'b1;
  assign tx_busy = tx_start;
  assign tx_done = !tx_busy && tx_start;
  
  // uart_rx模块桩
  assign rx_ready = rx_in;
  assign rx_byte = 8'hAA;
  assign frame_err = 1'b0;
  
endmodule