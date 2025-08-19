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
  // 缓冲区存储
  reg [10:0] id_buffer [0:BUFFER_DEPTH-1];
  reg [7:0] data_buffer [0:BUFFER_DEPTH-1][0:7];
  reg [3:0] dlc_buffer [0:BUFFER_DEPTH-1];
  reg [$clog2(BUFFER_DEPTH):0] rd_ptr, wr_ptr;
  
  // 组合逻辑信号
  wire [$clog2(BUFFER_DEPTH):0] next_rd_ptr, next_wr_ptr;
  wire [3:0] next_buffer_level;
  wire next_buffer_empty, next_buffer_full;
  wire should_write, should_read;
  
  // 组合逻辑部分 - 缓冲区控制逻辑
  assign should_write = rx_done && !buffer_full;
  assign should_read = tx_request && !buffer_empty && tx_done;
  
  assign next_rd_ptr = should_read ? rd_ptr + 1'b1 : rd_ptr;
  assign next_wr_ptr = should_write ? wr_ptr + 1'b1 : wr_ptr;
  
  // 条件求和计算 - 纯组合逻辑
  assign next_buffer_level = buffer_level + (should_write ? 4'b0001 : 4'b0000) - 
                                           (should_read ? 4'b0001 : 4'b0000);
  
  // 缓冲区状态标志 - 组合逻辑
  assign next_buffer_empty = (next_buffer_level == 0);
  assign next_buffer_full = (next_buffer_level == BUFFER_DEPTH);
  
  // 时序逻辑部分 - 更新寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      wr_ptr <= 0;
      buffer_full <= 0;
      buffer_empty <= 1;
      buffer_level <= 0;
      
      // 初始化输出信号
      tx_id <= 0;
      tx_dlc <= 0;
      for (int i = 0; i < 8; i++) begin
        tx_data[i] <= 0;
      end
    end 
    else begin
      // 更新指针和状态
      rd_ptr <= next_rd_ptr;
      wr_ptr <= next_wr_ptr;
      buffer_level <= next_buffer_level;
      buffer_empty <= next_buffer_empty;
      buffer_full <= next_buffer_full;
      
      // 写入操作 - 时序逻辑
      if (should_write) begin
        id_buffer[wr_ptr[$clog2(BUFFER_DEPTH)-1:0]] <= rx_id;
        dlc_buffer[wr_ptr[$clog2(BUFFER_DEPTH)-1:0]] <= rx_dlc;
        for (int i = 0; i < 8; i++) begin
          data_buffer[wr_ptr[$clog2(BUFFER_DEPTH)-1:0]][i] <= rx_data[i];
        end
      end
      
      // 读取操作 - 时序逻辑
      if (should_read) begin
        tx_id <= id_buffer[rd_ptr[$clog2(BUFFER_DEPTH)-1:0]];
        tx_dlc <= dlc_buffer[rd_ptr[$clog2(BUFFER_DEPTH)-1:0]];
        for (int i = 0; i < 8; i++) begin
          tx_data[i] <= data_buffer[rd_ptr[$clog2(BUFFER_DEPTH)-1:0]][i];
        end
      end
    end
  end
endmodule