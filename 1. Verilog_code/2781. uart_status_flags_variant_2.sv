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
  // 接收器流水线寄存器
  reg rx_active, rx_active_stage1, rx_active_stage2;
  reg [3:0] rx_count, rx_count_stage1, rx_count_stage2;
  reg [7:0] rx_shift, rx_shift_stage1, rx_shift_stage2;
  reg break_detected, break_detected_stage1, break_detected_stage2;
  reg overrun_error, overrun_error_stage1, overrun_error_stage2;
  
  // 发送器流水线寄存器
  reg tx_active, tx_active_stage1, tx_active_stage2;
  reg [3:0] tx_count, tx_count_stage1, tx_count_stage2;
  reg [7:0] tx_shift, tx_shift_stage1, tx_shift_stage2;
  reg tx_out_next, tx_out_stage1;
  reg tx_done_next, tx_done_stage1;
  reg tx_start_bit, tx_start_bit_stage1, tx_start_bit_stage2;
  reg tx_data_bits, tx_data_bits_stage1, tx_data_bits_stage2;
  reg tx_stop_bit, tx_stop_bit_stage1, tx_stop_bit_stage2;
  
  // FIFO状态寄存器
  reg fifo_full, fifo_full_stage1;
  reg fifo_empty, fifo_empty_stage1;
  
  // 输入寄存器 - 增加流水线第一级
  reg rx_in_reg, tx_start_reg;
  reg [DATA_W-1:0] tx_data_reg;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      rx_in_reg <= 1'b1;
      tx_start_reg <= 1'b0;
      tx_data_reg <= {DATA_W{1'b0}};
    end else begin
      rx_in_reg <= rx_in;
      tx_start_reg <= tx_start;
      tx_data_reg <= tx_data;
    end
  end
  
  // 优化连续赋值，减少逻辑层次
  assign {rx_idle, tx_idle} = {~rx_active_stage2, ~tx_active_stage2};
  assign rx_error = overrun_error_stage2 | break_detected_stage2;
  assign status_flags = {fifo_full_stage1, fifo_empty_stage1, overrun_error_stage2, break_detected_stage2};
  assign rx_data = rx_shift_stage2;
  assign rx_ready = (rx_count_stage2 == 4'd10);
  
  // 接收器逻辑 - 第一级流水线：计算下一状态
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_active <= 1'b0;
      rx_count <= 4'b0;
      rx_shift <= 8'b0;
      break_detected <= 1'b0;
      overrun_error <= 1'b0;
    end else begin
      if (~rx_active & ~rx_in_reg) begin
        rx_active <= 1'b1;
        rx_count <= 4'b0;
      end else if (rx_active) begin
        if (rx_count < 4'd9) begin
          rx_count <= rx_count + 4'd1;
          rx_shift <= {rx_in_reg, rx_shift[7:1]};
          break_detected <= (rx_count == 4'd8) ? ~rx_in_reg : break_detected;
        end else begin
          rx_active <= 1'b0;
          overrun_error <= overrun_error | (rx_count == 4'd9);
          rx_count <= 4'd10;
        end
      end
    end
  end
  
  // 接收器逻辑 - 第二级流水线：传播状态
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_active_stage1 <= 1'b0;
      rx_count_stage1 <= 4'b0;
      rx_shift_stage1 <= 8'b0;
      break_detected_stage1 <= 1'b0;
      overrun_error_stage1 <= 1'b0;
    end else begin
      rx_active_stage1 <= rx_active;
      rx_count_stage1 <= rx_count;
      rx_shift_stage1 <= rx_shift;
      break_detected_stage1 <= break_detected;
      overrun_error_stage1 <= overrun_error;
    end
  end
  
  // 接收器逻辑 - 第三级流水线：输出状态
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_active_stage2 <= 1'b0;
      rx_count_stage2 <= 4'b0;
      rx_shift_stage2 <= 8'b0;
      break_detected_stage2 <= 1'b0;
      overrun_error_stage2 <= 1'b0;
    end else begin
      rx_active_stage2 <= rx_active_stage1;
      rx_count_stage2 <= rx_count_stage1;
      rx_shift_stage2 <= rx_shift_stage1;
      break_detected_stage2 <= break_detected_stage1;
      overrun_error_stage2 <= overrun_error_stage1;
    end
  end
  
  // 发送器逻辑 - 第一级流水线：计算下一状态
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_active <= 1'b0;
      tx_count <= 4'b0;
      tx_shift <= 8'b0;
      tx_out_next <= 1'b1;
      tx_done_next <= 1'b0;
      tx_start_bit <= 1'b0;
      tx_data_bits <= 1'b0;
      tx_stop_bit <= 1'b0;
    end else begin
      // 默认保持状态
      tx_done_next <= tx_done & ~tx_start_reg;
      
      // 状态转换逻辑
      if (~tx_active & tx_start_reg) begin
        tx_active <= 1'b1;
        tx_count <= 4'b0;
        tx_shift <= tx_data_reg;
        tx_out_next <= 1'b0; // Start bit
        tx_done_next <= 1'b0;
        tx_start_bit <= 1'b1;
        tx_data_bits <= 1'b0;
        tx_stop_bit <= 1'b0;
      end else if (tx_active) begin
        tx_start_bit <= 1'b0;
        
        if (tx_count < 4'd8) begin
          tx_count <= tx_count + 4'd1;
          tx_out_next <= tx_shift[0];
          tx_shift <= {1'b0, tx_shift[7:1]};
          tx_data_bits <= 1'b1;
        end else if (tx_count == 4'd8) begin
          tx_out_next <= 1'b1;
          tx_count <= tx_count + 4'd1;
          tx_data_bits <= 1'b0;
          tx_stop_bit <= 1'b1;
        end else begin
          tx_active <= 1'b0;
          tx_done_next <= 1'b1;
          tx_stop_bit <= 1'b0;
        end
      end
    end
  end
  
  // 发送器逻辑 - 第二级流水线：传播状态
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_active_stage1 <= 1'b0;
      tx_count_stage1 <= 4'b0;
      tx_shift_stage1 <= 8'b0;
      tx_out_stage1 <= 1'b1;
      tx_done_stage1 <= 1'b0;
      tx_start_bit_stage1 <= 1'b0;
      tx_data_bits_stage1 <= 1'b0;
      tx_stop_bit_stage1 <= 1'b0;
    end else begin
      tx_active_stage1 <= tx_active;
      tx_count_stage1 <= tx_count;
      tx_shift_stage1 <= tx_shift;
      tx_out_stage1 <= tx_out_next;
      tx_done_stage1 <= tx_done_next;
      tx_start_bit_stage1 <= tx_start_bit;
      tx_data_bits_stage1 <= tx_data_bits;
      tx_stop_bit_stage1 <= tx_stop_bit;
    end
  end
  
  // 发送器逻辑 - 第三级流水线：输出状态
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_active_stage2 <= 1'b0;
      tx_count_stage2 <= 4'b0;
      tx_shift_stage2 <= 8'b0;
      tx_out <= 1'b1;
      tx_done <= 1'b0;
      tx_start_bit_stage2 <= 1'b0;
      tx_data_bits_stage2 <= 1'b0;
      tx_stop_bit_stage2 <= 1'b0;
    end else begin
      tx_active_stage2 <= tx_active_stage1;
      tx_count_stage2 <= tx_count_stage1;
      tx_shift_stage2 <= tx_shift_stage1;
      tx_out <= tx_out_stage1;
      tx_done <= tx_done_stage1;
      tx_start_bit_stage2 <= tx_start_bit_stage1;
      tx_data_bits_stage2 <= tx_data_bits_stage1;
      tx_stop_bit_stage2 <= tx_stop_bit_stage1;
    end
  end
  
  // FIFO状态检测 - 两级流水线化
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_full <= 1'b0;
      fifo_empty <= 1'b1;
    end else begin
      fifo_full <= rx_ready & ~tx_idle;
      fifo_empty <= tx_idle & ~rx_ready;
    end
  end
  
  // FIFO状态输出级
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_full_stage1 <= 1'b0;
      fifo_empty_stage1 <= 1'b1;
    end else begin
      fifo_full_stage1 <= fifo_full;
      fifo_empty_stage1 <= fifo_empty;
    end
  end
endmodule