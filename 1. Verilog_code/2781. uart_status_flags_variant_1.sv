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
  // 原始信号
  reg break_detected;
  reg overrun_error;
  reg fifo_full, fifo_empty;
  reg rx_active, tx_active;
  reg [7:0] rx_shift, tx_shift;
  
  // 高扇出信号缓冲
  reg rx_in_buf1, rx_in_buf2;  // rx_in信号缓冲
  reg [3:0] rx_count, rx_count_buf1, rx_count_buf2;  // rx_count信号缓冲
  reg [3:0] tx_count, tx_count_buf1, tx_count_buf2;  // tx_count信号缓冲
  
  // 为高扇出信号添加缓冲寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_in_buf1 <= 1'b1;
      rx_in_buf2 <= 1'b1;
      rx_count_buf1 <= 4'b0;
      rx_count_buf2 <= 4'b0;
      tx_count_buf1 <= 4'b0;
      tx_count_buf2 <= 4'b0;
    end else begin
      // 为rx_in添加两级缓冲
      rx_in_buf1 <= rx_in;
      rx_in_buf2 <= rx_in_buf1;
      
      // 为rx_count添加两级缓冲
      rx_count_buf1 <= rx_count;
      rx_count_buf2 <= rx_count_buf1;
      
      // 为tx_count添加两级缓冲
      tx_count_buf1 <= tx_count;
      tx_count_buf2 <= tx_count_buf1;
    end
  end
  
  // 输出信号逻辑，使用缓冲后的信号
  assign rx_idle = !rx_active;
  assign tx_idle = !tx_active;
  assign rx_error = overrun_error || break_detected;
  assign status_flags = {fifo_full, fifo_empty, overrun_error, break_detected};
  assign rx_data = rx_shift;
  assign rx_ready = (rx_count_buf1 == 10);
  
  // Status logic for receiver - 使用缓冲信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_active <= 0;
      rx_count <= 0;
      rx_shift <= 0;
      break_detected <= 0;
      overrun_error <= 0;
    end else begin
      if (!rx_active && rx_in_buf1 == 0) begin
        rx_active <= 1;
        rx_count <= 0;
      end else if (rx_active) begin
        if (rx_count < 9) begin
          rx_count <= rx_count + 1;
          rx_shift <= {rx_in_buf1, rx_shift[7:1]};
          break_detected <= break_detected || (rx_count == 9 && rx_in_buf1 == 0);
        end else begin
          rx_active <= 0;
          if (rx_count_buf2 == 10) overrun_error <= 1;
          rx_count <= 10;
        end
      end
    end
  end
  
  // Status logic for transmitter - 使用缓冲信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_active <= 0;
      tx_count <= 0;
      tx_shift <= 0;
      tx_out <= 1;
      tx_done <= 0;
    end else begin
      if (!tx_active && tx_start) begin
        tx_active <= 1;
        tx_count <= 0;
        tx_shift <= tx_data;
        tx_out <= 0;
        tx_done <= 0;
      end else if (tx_active) begin
        if (tx_count < 8) begin
          tx_count <= tx_count + 1;
          tx_out <= tx_shift[0];
          tx_shift <= {1'b0, tx_shift[7:1]};
        end else if (tx_count == 8) begin
          tx_out <= 1;
          tx_count <= tx_count + 1;
        end else begin
          tx_active <= 0;
          tx_done <= 1;
        end
      end
    end
  end
endmodule