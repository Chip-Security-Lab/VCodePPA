module uart_status_flags #(parameter DATA_W = 8) (
  input wire clk, rst_n,
  input wire rx_in, tx_start,
  input wire [DATA_W-1:0] tx_data,
  output reg tx_out,
  output wire [DATA_W-1:0] rx_data,
  output wire rx_idle, tx_idle, rx_error, rx_ready, 
  output reg tx_done, // 改为reg类型
  output wire [3:0] status_flags // [fifo_full, fifo_empty, overrun, break]
);
  reg break_detected;
  reg overrun_error;
  reg fifo_full, fifo_empty;
  reg rx_active, tx_active;
  reg [7:0] rx_shift, tx_shift;
  reg [3:0] rx_count, tx_count;
  
  assign rx_idle = !rx_active;
  assign tx_idle = !tx_active;
  assign rx_error = overrun_error || break_detected;
  assign status_flags = {fifo_full, fifo_empty, overrun_error, break_detected};
  assign rx_data = rx_shift; // 添加rx_data赋值
  assign rx_ready = (rx_count == 10); // 添加rx_ready赋值
  
  // Status logic for receiver
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_active <= 0;
      rx_count <= 0;
      rx_shift <= 0;
      break_detected <= 0;
      overrun_error <= 0;
    end else begin
      if (!rx_active && rx_in == 0) begin
        rx_active <= 1;
        rx_count <= 0;
      end else if (rx_active) begin
        if (rx_count < 9) begin
          rx_count <= rx_count + 1;
          rx_shift <= {rx_in, rx_shift[7:1]};
          break_detected <= break_detected || (rx_count == 9 && rx_in == 0);
        end else begin
          rx_active <= 0;
          if (rx_ready) overrun_error <= 1;
          rx_count <= 10; // 设置rx_ready条件
        end
      end
    end
  end
  
  // Status logic for transmitter
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
        tx_out <= 0; // Start bit
        tx_done <= 0;
      end else if (tx_active) begin
        if (tx_count < 8) begin
          tx_count <= tx_count + 1;
          tx_out <= tx_shift[0];
          tx_shift <= {1'b0, tx_shift[7:1]};
        end else if (tx_count == 8) begin
          tx_out <= 1; // Stop bit
          tx_count <= tx_count + 1;
        end else begin
          tx_active <= 0;
          tx_done <= 1;
        end
      end
    end
  end
endmodule