//SystemVerilog
module uart_status_flags #(parameter DATA_W = 8) (
  input wire clk, rst_n,
  input wire rx_in, tx_start,
  input wire [DATA_W-1:0] tx_data,
  output reg tx_out,
  output wire [DATA_W-1:0] rx_data,
  output wire rx_idle, tx_idle, rx_error, rx_ready, 
  output reg tx_done,
  output wire [3:0] status_flags
);
  // 接收器状态寄存器
  reg break_detected;
  reg overrun_error;
  reg fifo_full, fifo_empty;
  reg rx_active, tx_active;
  reg [7:0] rx_shift, tx_shift;
  reg [3:0] rx_count, tx_count;
  
  // 流水线寄存器
  reg rx_active_pipe;
  reg break_detected_pipe;
  reg overrun_error_pipe;
  reg [7:0] rx_shift_pipe;
  reg [3:0] rx_count_pipe;
  reg tx_active_pipe;
  reg [7:0] tx_shift_pipe;
  reg [3:0] tx_count_pipe;
  
  // 组合逻辑路径切割
  wire rx_idle_comb, tx_idle_comb;
  wire rx_error_comb;
  wire [3:0] status_flags_comb;
  wire rx_ready_comb;
  
  // 第一级组合逻辑
  assign rx_idle_comb = !rx_active;
  assign tx_idle_comb = !tx_active;
  assign rx_error_comb = overrun_error || break_detected;
  assign status_flags_comb = {fifo_full, fifo_empty, overrun_error, break_detected};
  assign rx_ready_comb = (rx_count == 10);
  
  // 第二级组合逻辑（流水线后）
  assign rx_idle = !rx_active_pipe;
  assign tx_idle = !tx_active_pipe;
  assign rx_error = overrun_error_pipe || break_detected_pipe;
  assign status_flags = {fifo_full, fifo_empty, overrun_error_pipe, break_detected_pipe};
  assign rx_data = rx_shift_pipe;
  assign rx_ready = (rx_count_pipe == 10);
  
  // 流水线寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_active_pipe <= 0;
      break_detected_pipe <= 0;
      overrun_error_pipe <= 0;
      rx_shift_pipe <= 0;
      rx_count_pipe <= 0;
      tx_active_pipe <= 0;
      tx_shift_pipe <= 0;
      tx_count_pipe <= 0;
    end else begin
      rx_active_pipe <= rx_active;
      break_detected_pipe <= break_detected;
      overrun_error_pipe <= overrun_error;
      rx_shift_pipe <= rx_shift;
      rx_count_pipe <= rx_count;
      tx_active_pipe <= tx_active;
      tx_shift_pipe <= tx_shift;
      tx_count_pipe <= tx_count;
    end
  end
  
  // 接收器状态逻辑 - 分步处理
  reg rx_start_detected;
  reg [3:0] rx_process_state;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_active <= 0;
      rx_count <= 0;
      rx_shift <= 0;
      break_detected <= 0;
      overrun_error <= 0;
      rx_start_detected <= 0;
      rx_process_state <= 0;
    end else begin
      // 扁平化的条件结构
      if (!rx_active && rx_in == 0 && !rx_start_detected) begin
        rx_start_detected <= 1;
        rx_process_state <= 1;
      end else if (rx_process_state == 1) begin
        rx_active <= 1;
        rx_count <= 0;
        rx_process_state <= 2;
      end else if (rx_process_state == 2 && rx_count < 9) begin
        rx_count <= rx_count + 1;
        rx_shift <= {rx_in, rx_shift[7:1]};
        if (rx_count == 8 && rx_in == 0)
          break_detected <= 1;
      end else if (rx_process_state == 2 && rx_count >= 9) begin
        rx_active <= 0;
        if (rx_ready_comb) 
          overrun_error <= 1;
        rx_count <= 10;
        rx_process_state <= 0;
        rx_start_detected <= 0;
      end else if (rx_process_state > 2) begin
        rx_process_state <= 0;
      end
      
      // 复位起始位检测（如果处于空闲状态且没有开始位）
      if (!rx_active && rx_in == 1)
        rx_start_detected <= 0;
    end
  end
  
  // 发送器状态逻辑 - 流水线处理
  reg tx_process_started;
  reg [2:0] tx_process_state;
  reg [7:0] tx_data_pipe;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_active <= 0;
      tx_count <= 0;
      tx_shift <= 0;
      tx_out <= 1;
      tx_done <= 0;
      tx_process_started <= 0;
      tx_process_state <= 0;
      tx_data_pipe <= 0;
    end else begin
      // 扁平化的条件结构
      if (!tx_active && tx_start && !tx_process_started) begin
        tx_process_started <= 1;
        tx_data_pipe <= tx_data;
        tx_process_state <= 1;
      end else if (tx_process_state == 1) begin
        tx_active <= 1;
        tx_count <= 0;
        tx_shift <= tx_data_pipe;
        tx_out <= 0; // 起始位
        tx_done <= 0;
        tx_process_state <= 2;
      end else if (tx_process_state == 2 && tx_count < 8) begin
        tx_count <= tx_count + 1;
        tx_out <= tx_shift[0];
        tx_shift <= {1'b0, tx_shift[7:1]};
      end else if (tx_process_state == 2 && tx_count == 8) begin
        tx_out <= 1; // 停止位
        tx_count <= tx_count + 1;
      end else if (tx_process_state == 2 && tx_count > 8) begin
        tx_active <= 0;
        tx_done <= 1;
        tx_process_state <= 0;
        tx_process_started <= 0;
      end else if (tx_process_state > 2) begin
        tx_process_state <= 0;
      end
    end
  end
endmodule