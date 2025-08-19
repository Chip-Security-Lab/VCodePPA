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
  reg [DATA_WIDTH-1:0] tx_buffer [0:BUFFER_DEPTH-1];
  reg [$clog2(BUFFER_DEPTH):0] tx_count, tx_rd_ptr, tx_wr_ptr;
  
  // 寄存寄输入信号，将寄存器前移
  reg [DATA_WIDTH-1:0] tx_data_reg;
  reg tx_valid_reg;
  
  // 使用二进制补码减法算法实现减法运算
  // 计算用于溢出检测的信号
  wire [10:0] buffer_full_threshold;
  wire [10:0] tx_count_comp;
  wire [10:0] comp_result;
  wire comp_overflow;
  
  // 设置缓冲区满阈值
  assign buffer_full_threshold = BUFFER_DEPTH;
  
  // 使用二进制补码进行减法: tx_count_comp = ~tx_count + 1 (二进制取反加一)
  assign tx_count_comp = (~{{(10-$clog2(BUFFER_DEPTH)){1'b0}}, tx_count}) + 11'b1;
  
  // 计算 buffer_full_threshold - tx_count 使用补码加法
  assign comp_result = buffer_full_threshold + tx_count_comp;
  
  // 检测是否有足够空间 (buffer_full_threshold > tx_count)
  assign comp_overflow = (buffer_full_threshold[10] ^ tx_count_comp[10]) & 
                         (buffer_full_threshold[10] ^ comp_result[10]);
  
  // buffer有空间时tx_ready有效
  assign tx_ready = |comp_result || comp_overflow;
  
  // 计算下一个写指针
  wire [$clog2(BUFFER_DEPTH):0] next_wr_ptr;
  wire [$clog2(BUFFER_DEPTH):0] next_count;
  
  assign next_wr_ptr = (tx_wr_ptr + 1) % BUFFER_DEPTH;
  assign next_count = tx_valid_reg && tx_ready ? tx_count + 1 : tx_count;
  
  // 寄存输入信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_reg <= {DATA_WIDTH{1'b0}};
      tx_valid_reg <= 1'b0;
    end else begin
      tx_data_reg <= tx_data;
      tx_valid_reg <= tx_valid;
    end
  end
  
  // 优化后的主状态更新逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_count <= 0;
      tx_rd_ptr <= 0;
      tx_wr_ptr <= 0;
    end else begin
      if (tx_valid_reg && tx_ready) begin
        tx_buffer[tx_wr_ptr] <= tx_data_reg;
        tx_wr_ptr <= next_wr_ptr;
        tx_count <= next_count;
      end
    end
  end
endmodule