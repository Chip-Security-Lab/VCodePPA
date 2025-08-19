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
  
  // 寄存器指针和状态信号
  reg [$clog2(BUFFER_DEPTH):0] rd_ptr, wr_ptr;
  
  // 寄存输入信号以改善时序
  reg rx_done_reg;
  reg [10:0] rx_id_reg;
  reg [7:0] rx_data_reg [0:7];
  reg [3:0] rx_dlc_reg;
  reg tx_request_reg, tx_done_reg;
  
  // 条件反相减法器信号
  reg sub_op;                // 减法操作标志
  reg [10:0] minuend;        // 被减数
  reg [10:0] subtrahend;     // 减数
  reg [10:0] sub_result;     // 减法结果
  reg [10:0] complemented;   // 条件反相值
  reg carry_in;              // 进位输入

  // 输入寄存优化 - 前向寄存器重定时
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_done_reg <= 0;
      rx_id_reg <= 0;
      rx_dlc_reg <= 0;
      tx_request_reg <= 0;
      tx_done_reg <= 0;
      for (int i = 0; i < 8; i++) begin
        rx_data_reg[i] <= 0;
      end
    end else begin
      rx_done_reg <= rx_done;
      rx_id_reg <= rx_id;
      rx_dlc_reg <= rx_dlc;
      tx_request_reg <= tx_request;
      tx_done_reg <= tx_done;
      for (int i = 0; i < 8; i++) begin
        rx_data_reg[i] <= rx_data[i];
      end
    end
  end
  
  // 条件反相减法器实现
  always @(*) begin
    if (tx_request_reg && !buffer_empty && tx_done_reg) begin
      // 减法操作 buffer_level - 1
      sub_op = 1'b1;
      minuend = {7'b0, buffer_level};
      subtrahend = 11'd1;
    end else if (rx_done_reg && !buffer_full) begin
      // 加法操作 buffer_level + 1
      sub_op = 1'b0;
      minuend = {7'b0, buffer_level};
      subtrahend = 11'd1;
    end else begin
      sub_op = 1'b0;
      minuend = {7'b0, buffer_level};
      subtrahend = 11'd0;
    end
    
    // 条件反相逻辑
    complemented = sub_op ? ~subtrahend : subtrahend;
    carry_in = sub_op ? 1'b1 : 1'b0;
    
    // 计算结果
    sub_result = minuend + complemented + carry_in;
  end
  
  // 主控制逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      wr_ptr <= 0;
      buffer_full <= 0;
      buffer_empty <= 1;
      buffer_level <= 0;
      tx_id <= 0;
      tx_dlc <= 0;
      for (int i = 0; i < 8; i++) begin
        tx_data[i] <= 0;
      end
    end else begin
      // 写入缓冲区逻辑
      if (rx_done_reg && !buffer_full) begin
        id_buffer[wr_ptr[$clog2(BUFFER_DEPTH)-1:0]] <= rx_id_reg;
        dlc_buffer[wr_ptr[$clog2(BUFFER_DEPTH)-1:0]] <= rx_dlc_reg;
        for (int i = 0; i < 8; i++) begin
          data_buffer[wr_ptr[$clog2(BUFFER_DEPTH)-1:0]][i] <= rx_data_reg[i];
        end
        
        wr_ptr <= wr_ptr + 1;
        
        // 更新缓冲区状态 - 使用条件反相减法器结果
        buffer_level <= sub_result[3:0];
        buffer_empty <= 0;
        if (buffer_level == BUFFER_DEPTH - 1) begin
          buffer_full <= 1;
        end
      end
      
      // 读取缓冲区逻辑
      if (tx_request_reg && !buffer_empty && tx_done_reg) begin
        tx_id <= id_buffer[rd_ptr[$clog2(BUFFER_DEPTH)-1:0]];
        tx_dlc <= dlc_buffer[rd_ptr[$clog2(BUFFER_DEPTH)-1:0]];
        for (int i = 0; i < 8; i++) begin
          tx_data[i] <= data_buffer[rd_ptr[$clog2(BUFFER_DEPTH)-1:0]][i];
        end
        
        rd_ptr <= rd_ptr + 1;
        
        // 更新缓冲区状态 - 使用条件反相减法器结果
        buffer_level <= sub_result[3:0];
        buffer_full <= 0;
        if (buffer_level == 1) begin
          buffer_empty <= 1;
        end
      end
    end
  end
endmodule