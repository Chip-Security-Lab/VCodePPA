//SystemVerilog
module fifo_parity_gen(
  input wire clk,         // 时钟信号
  input wire rst_n,       // 低电平有效复位信号
  input wire wr_en,       // 写使能信号
  input wire rd_en,       // 读使能信号
  input wire [7:0] data_in, // 输入数据
  output reg fifo_parity, // FIFO奇偶校验输出
  output reg [3:0] fifo_count // FIFO计数器
);
  // 定义流水线寄存器和控制信号
  reg parity_accumulator;     // 累积奇偶校验
  reg [7:0] data_stage1;      // 数据流水线寄存器
  reg wr_en_stage1;           // 写使能流水线寄存器
  reg rd_en_stage1;           // 读使能流水线寄存器
  reg [3:0] fifo_count_next;  // 下一个FIFO计数值
  reg parity_bit;             // 当前数据的奇偶校验位
  
  // 第一级流水线：数据捕获和预处理
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_stage1 <= 8'h00;
      wr_en_stage1 <= 1'b0;
      rd_en_stage1 <= 1'b0;
      parity_bit <= 1'b0;
    end else begin
      data_stage1 <= data_in;
      wr_en_stage1 <= wr_en;
      rd_en_stage1 <= rd_en;
      parity_bit <= ^data_in; // 计算输入数据的奇偶校验
    end
  end
  
  // 计算下一个FIFO计数值的组合逻辑
  always @(*) begin
    fifo_count_next = fifo_count;
    
    if (wr_en_stage1 && !rd_en_stage1) 
      fifo_count_next = fifo_count + 1'b1;
    else if (!wr_en_stage1 && rd_en_stage1 && (fifo_count > 0))
      fifo_count_next = fifo_count - 1'b1;
  end
  
  // 第二级流水线：处理计数和奇偶校验
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_count <= 4'b0000;
      parity_accumulator <= 1'b0;
      fifo_parity <= 1'b0;
    end else begin
      fifo_count <= fifo_count_next;
      
      // 写操作时更新累积奇偶校验
      if (wr_en_stage1)
        parity_accumulator <= parity_accumulator ^ parity_bit;
      
      // 读操作时输出奇偶校验
      if (rd_en_stage1 && (fifo_count > 0))
        fifo_parity <= parity_accumulator;
    end
  end
  
endmodule