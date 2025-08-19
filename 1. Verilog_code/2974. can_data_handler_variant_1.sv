//SystemVerilog
module can_data_handler #(
  parameter DATA_WIDTH = 8,
  parameter BUFFER_DEPTH = 4
)(
  input wire clk, rst_n,
  input wire [DATA_WIDTH-1:0] tx_data,
  input wire tx_valid,
  output wire tx_ready,
  input wire [10:0] msg_id,
  output reg [DATA_WIDTH-1:0] rx_data,
  output reg rx_valid,
  input wire rx_ready
);
  // 数据缓冲区定义
  reg [DATA_WIDTH-1:0] tx_buffer [0:BUFFER_DEPTH-1];
  
  // 计数器和指针
  reg [$clog2(BUFFER_DEPTH):0] tx_count;
  reg [$clog2(BUFFER_DEPTH):0] tx_rd_ptr;
  reg [$clog2(BUFFER_DEPTH):0] tx_wr_ptr;
  
  // 准备就绪信号
  assign tx_ready = (tx_count < BUFFER_DEPTH);
  
  // 合并的always块 - 处理所有时序逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位所有寄存器
      tx_count <= 0;
      tx_rd_ptr <= 0;
      tx_wr_ptr <= 0;
      rx_valid <= 0;
      rx_data <= {DATA_WIDTH{1'b0}};
    end else begin
      // 处理发送数据逻辑
      if (tx_valid && tx_ready) begin
        tx_buffer[tx_wr_ptr] <= tx_data;
        tx_wr_ptr <= (tx_wr_ptr + 1'b1) % BUFFER_DEPTH;
        tx_count <= tx_count + 1'b1;
      end
    end
  end
endmodule