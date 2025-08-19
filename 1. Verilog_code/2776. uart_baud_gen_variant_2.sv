//SystemVerilog
module uart_baud_gen #(parameter CLK_FREQ = 50_000_000) (
  input wire sys_clk, rst_n,
  input wire [15:0] baud_val, // Desired baud rate
  input wire [7:0] tx_data,
  input wire tx_start,
  output reg tx_out, tx_done
);
  // 状态定义
  localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  
  // 寄存器定义
  reg [1:0] state, next_state;
  reg [15:0] baud_counter;
  reg [15:0] bit_duration;
  reg [2:0] bit_idx;
  reg [7:0] tx_reg;
  
  // 预计算信号 - 将复杂表达式分解为多个简单计算
  wire baud_tick = (baud_counter >= (bit_duration - 16'd1));
  wire last_bit = (bit_idx == 3'h7);
  wire in_idle = (state == IDLE);
  wire in_start = (state == START);
  wire in_data = (state == DATA);
  wire in_stop = (state == STOP);
  wire idle_to_start = in_idle && tx_start;
  
  // 预计算下一状态逻辑 - 分离状态转换判断
  always @(*) begin
    // 默认保持当前状态
    next_state = state;
    
    case (state)
      IDLE:   if (tx_start)           next_state = START;
      START:  if (baud_tick)          next_state = DATA;
      DATA:   if (baud_tick && last_bit) next_state = STOP;
      STOP:   if (baud_tick)          next_state = IDLE;
      default:                        next_state = IDLE;
    endcase
  end
  
  // 分离计算bit_duration，减少算术路径长度
  reg [15:0] next_bit_duration;
  
  always @(*) begin
    if (idle_to_start || (!rst_n)) begin
      next_bit_duration = CLK_FREQ / baud_val;
    end else begin
      next_bit_duration = bit_duration;
    end
  end
  
  // 更新bit_duration寄存器
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_duration <= 16'd0;
    end else begin
      bit_duration <= next_bit_duration;
    end
  end
  
  // 优化的波特率计数器，减少条件判断链
  reg [15:0] next_baud_counter;
  
  always @(*) begin
    if (in_idle && !tx_start) begin
      next_baud_counter = 16'd0;
    end else if (baud_tick) begin
      next_baud_counter = 16'd0;
    end else begin
      next_baud_counter = baud_counter + 16'd1;
    end
  end
  
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_counter <= 16'd0;
    end else begin
      baud_counter <= next_baud_counter;
    end
  end
  
  // bit索引控制 - 分离逻辑减少关键路径
  reg [2:0] next_bit_idx;
  
  always @(*) begin
    if (!in_data || !baud_tick) begin
      next_bit_idx = bit_idx;
    end else begin
      next_bit_idx = bit_idx + 3'h1;
    end
  end
  
  // TX输出控制逻辑 - 使用预解码减少多路复用器深度
  reg next_tx_out;
  
  always @(*) begin
    case (state)
      IDLE:   next_tx_out = 1'b1;
      START:  next_tx_out = 1'b0;
      DATA:   next_tx_out = tx_reg[bit_idx];
      STOP:   next_tx_out = 1'b1;
      default: next_tx_out = 1'b1;
    endcase
  end
  
  // 完成信号生成逻辑
  wire next_tx_done = in_stop && baud_tick;
  
  // 更新状态和控制寄存器
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_idx <= 3'h0;
      tx_out <= 1'b1;
      tx_done <= 1'b0;
      tx_reg <= 8'h0;
    end else begin
      state <= next_state;
      bit_idx <= next_bit_idx;
      tx_out <= next_tx_out;
      tx_done <= next_tx_done;
      
      // 数据寄存器更新
      if (idle_to_start) begin
        tx_reg <= tx_data;
      end
    end
  end
endmodule