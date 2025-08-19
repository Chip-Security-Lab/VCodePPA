//SystemVerilog
module can_buffer_controller #(
  parameter BUFFER_DEPTH = 8
)(
  input wire clk, rst_n,
  input wire rx_done,
  input wire [10:0] rx_id,
  input wire [7:0] rx_data [0:7],
  input wire [3:0] rx_dlc,
  input wire tx_request, tx_done,
  output reg [10:0] tx_id,
  output reg [7:0] tx_data [0:7],
  output reg [3:0] tx_dlc,
  output reg buffer_full, buffer_empty,
  output reg [3:0] buffer_level
);
  reg [10:0] id_buffer [0:BUFFER_DEPTH-1];
  reg [7:0] data_buffer [0:BUFFER_DEPTH-1][0:7];
  reg [3:0] dlc_buffer [0:BUFFER_DEPTH-1];
  reg [$clog2(BUFFER_DEPTH):0] rd_ptr, wr_ptr;
  
  wire [$clog2(BUFFER_DEPTH):0] next_wr_ptr = (wr_ptr == BUFFER_DEPTH-1) ? 0 : wr_ptr + 1;
  wire [$clog2(BUFFER_DEPTH):0] next_rd_ptr = (rd_ptr == BUFFER_DEPTH-1) ? 0 : rd_ptr + 1;
  
  // 重置逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      wr_ptr <= 0;
      buffer_full <= 0;
      buffer_empty <= 1;
      buffer_level <= 0;
    end
  end
  
  // 写入缓冲区控制逻辑
  always @(posedge clk) begin
    if (rst_n && rx_done && !buffer_full) begin
      id_buffer[wr_ptr] <= rx_id;
      dlc_buffer[wr_ptr] <= rx_dlc;
      wr_ptr <= next_wr_ptr;
    end
  end
  
  // 写入缓冲区数据逻辑
  always @(posedge clk) begin
    if (rst_n && rx_done && !buffer_full) begin
      for (int i = 0; i < 8; i++) begin
        data_buffer[wr_ptr][i] <= rx_data[i];
      end
    end
  end
  
  // 读取缓冲区控制逻辑
  always @(posedge clk) begin
    if (rst_n && tx_request && !buffer_empty && tx_done) begin
      tx_id <= id_buffer[rd_ptr];
      tx_dlc <= dlc_buffer[rd_ptr];
      rd_ptr <= next_rd_ptr;
    end
  end
  
  // 读取缓冲区数据逻辑
  always @(posedge clk) begin
    if (rst_n && tx_request && !buffer_empty && tx_done) begin
      for (int i = 0; i < 8; i++) begin
        tx_data[i] <= data_buffer[rd_ptr][i];
      end
    end
  end
  
  // 缓冲区状态更新逻辑
  always @(posedge clk) begin
    if (rst_n) begin
      if (rx_done && !buffer_full) begin
        buffer_empty <= 0;
        buffer_full <= (next_wr_ptr == rd_ptr);
        buffer_level <= buffer_level + 1;
      end else if (tx_request && !buffer_empty && tx_done) begin
        buffer_full <= 0;
        buffer_empty <= (next_rd_ptr == wr_ptr);
        buffer_level <= buffer_level - 1;
      end
    end
  end
endmodule