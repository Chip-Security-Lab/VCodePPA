//SystemVerilog
module uart_interrupt #(parameter CLK_DIV = 16) (
  input wire clock, reset_n,
  input wire rx,
  output reg tx,
  input wire [7:0] tx_data,
  input wire tx_start,
  output reg [7:0] rx_data,
  output reg irq_tx_done, irq_rx_ready, irq_rx_break, irq_frame_err,
  input wire irq_tx_ack, irq_rx_ack, irq_break_ack, irq_frame_ack
);
  // 使用参数代替enum
  localparam RX_IDLE = 0, RX_START = 1, RX_DATA = 2, RX_STOP = 3;
  localparam TX_IDLE = 0, TX_START = 1, TX_DATA = 2, TX_STOP = 3;
  
  reg [1:0] rx_state;
  reg [1:0] tx_state;
  
  reg [7:0] rx_shift;
  reg [7:0] tx_shift;
  reg [3:0] rx_bit_count;
  reg [3:0] tx_bit_count;
  reg [7:0] clk_div_count;
  reg rx_break_detect;
  reg frame_error;
  
  // 接收器中断处理 - 扁平化if-else结构
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      irq_rx_ready <= 0;
      irq_rx_break <= 0;
      irq_frame_err <= 0;
    end else begin
      // 中断确认清除
      if (irq_rx_ack) irq_rx_ready <= 0;
      if (irq_break_ack) irq_rx_break <= 0;
      if (irq_frame_ack) irq_frame_err <= 0;
      
      // 中断触发设置 - 扁平化条件
      if (rx_state == RX_STOP && rx == 0) irq_frame_err <= 1;
      if (rx_state == RX_STOP && rx == 1 && frame_error == 0) irq_rx_ready <= 1;
      if (rx_state == RX_STOP && rx_break_detect) irq_rx_break <= 1;
    end
  end
  
  // 接收器状态机 - 扁平化if-else结构
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      rx_state <= RX_IDLE;
      rx_bit_count <= 0;
      rx_shift <= 0;
      rx_data <= 0;
      rx_break_detect <= 0;
      frame_error <= 0;
    end else begin
      // 扁平化状态转换
      if (rx_state == RX_IDLE && rx == 0) begin
        rx_state <= RX_START;
        rx_break_detect <= 1;
      end else if (rx_state == RX_START) begin
        rx_state <= RX_DATA;
        rx_bit_count <= 0;
      end else if (rx_state == RX_DATA) begin
        rx_shift <= {rx, rx_shift[7:1]};
        if (rx == 1) rx_break_detect <= 0;
        
        if (rx_bit_count == 7) begin
          rx_state <= RX_STOP;
        end else begin
          rx_bit_count <= rx_bit_count + 1;
        end
      end else if (rx_state == RX_STOP) begin
        rx_state <= RX_IDLE;
        if (rx == 0) begin
          frame_error <= 1;
        end else begin
          rx_data <= rx_shift;
          frame_error <= 0;
        end
        
        if (rx_break_detect) begin
          rx_break_detect <= 0;
        end
      end else if (rx_state > RX_STOP) begin
        rx_state <= RX_IDLE;
      end
    end
  end
  
  // 发送器中断处理 - 扁平化if-else结构
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      irq_tx_done <= 0;
    end else if (irq_tx_ack) begin
      irq_tx_done <= 0;
    end else if (tx_state == TX_STOP && clk_div_count == CLK_DIV-1) begin
      irq_tx_done <= 1;
    end
  end
  
  // 波特率分频计数器
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      clk_div_count <= 0;
    end else if (clk_div_count == CLK_DIV-1) begin
      clk_div_count <= 0;
    end else begin
      clk_div_count <= clk_div_count + 1;
    end
  end
  
  // 发送器状态机 - 扁平化if-else结构
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      tx_state <= TX_IDLE;
      tx_bit_count <= 0;
      tx_shift <= 0;
      tx <= 1;
    end else if (clk_div_count == CLK_DIV-1) begin
      // 扁平化状态转换
      if (tx_state == TX_IDLE && tx_start) begin
        tx_state <= TX_START;
        tx_shift <= tx_data;
      end else if (tx_state == TX_START) begin
        tx <= 0;
        tx_state <= TX_DATA;
        tx_bit_count <= 0;
      end else if (tx_state == TX_DATA) begin
        tx <= tx_shift[0];
        tx_shift <= {1'b0, tx_shift[7:1]};
        
        if (tx_bit_count == 7) begin
          tx_state <= TX_STOP;
        end else begin
          tx_bit_count <= tx_bit_count + 1;
        end
      end else if (tx_state == TX_STOP) begin
        tx <= 1;
        tx_state <= TX_IDLE;
      end else if (tx_state > TX_STOP) begin
        tx_state <= TX_IDLE;
      end
    end
  end
endmodule