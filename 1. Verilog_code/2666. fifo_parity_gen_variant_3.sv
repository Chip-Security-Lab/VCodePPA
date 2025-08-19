//SystemVerilog
module fifo_parity_gen(
  input clk, rst_n,
  input data_valid,        // 数据有效信号(由发送方控制)
  output reg data_ready,   // 数据准备好信号(由接收方控制)
  input [7:0] data_in,     // 输入数据
  output reg fifo_parity,  // 输出奇偶校验位
  output reg [3:0] fifo_count // FIFO计数器
);
  reg parity_accumulator;
  reg processing;          // 表示模块正在处理数据的状态
  
  // 状态机状态定义
  localparam IDLE = 1'b0;
  localparam BUSY = 1'b1;
  reg state;
  
  // 数据处理控制信号
  wire write_data = data_valid && data_ready;
  
  // 数据准备好逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_ready <= 1'b1;  // 初始状态为准备好接收
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (data_valid && data_ready) begin
            state <= BUSY;
            data_ready <= 1'b0;  // 开始处理数据，暂时不接收新数据
          end else begin
            data_ready <= 1'b1;  // 空闲状态，准备接收数据
          end
        end
        BUSY: begin
          // 模拟处理完成后，重新可以接收数据
          data_ready <= 1'b1;
          state <= IDLE;
        end
      endcase
    end
  end
  
  // 奇偶校验和FIFO计数逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_count <= 4'b0000;
      parity_accumulator <= 1'b0;
      fifo_parity <= 1'b0;
      processing <= 1'b0;
    end else begin
      if (write_data) begin
        // 写入数据时增加计数并更新奇偶校验累加器
        fifo_count <= fifo_count + 1'b1;
        parity_accumulator <= parity_accumulator ^ (^data_in);
        processing <= 1'b1;
      end else if (processing && state == IDLE) begin
        // 处理完成后更新输出奇偶校验位
        if (fifo_count > 0) begin
          fifo_count <= fifo_count - 1'b1;
          fifo_parity <= parity_accumulator;
        end
        processing <= 1'b0;
      end
    end
  end
endmodule