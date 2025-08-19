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
  localparam RX_IDLE = 2'b00, RX_START = 2'b01, RX_DATA = 2'b10, RX_STOP = 2'b11;
  localparam TX_IDLE = 2'b00, TX_START = 2'b01, TX_DATA = 2'b10, TX_STOP = 2'b11;
  
  reg [1:0] rx_state;
  reg [1:0] tx_state;
  
  reg [7:0] rx_shift;
  reg [7:0] tx_shift;
  reg [2:0] rx_bit_count; // 优化位宽，仅需3位表示0-7
  reg [2:0] tx_bit_count; // 优化位宽，仅需3位表示0-7
  reg [$clog2(CLK_DIV)-1:0] clk_div_count; // 动态位宽计算
  reg rx_break_detect;
  reg frame_error;
  
  // RX处理逻辑
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      rx_state <= RX_IDLE;
      rx_bit_count <= 0;
      rx_shift <= 0;
      rx_data <= 0;
      irq_rx_ready <= 0;
      irq_rx_break <= 0;
      irq_frame_err <= 0;
      rx_break_detect <= 0;
      frame_error <= 0;
    end else begin
      // 处理中断确认信号 - 优先处理
      if (irq_rx_ack) irq_rx_ready <= 0;
      if (irq_break_ack) irq_rx_break <= 0;
      if (irq_frame_ack) irq_frame_err <= 0;
      
      // 优化后的状态机 - 使用case结构提高可读性和综合效率
      case (rx_state)
        RX_IDLE: begin
          if (!rx) begin // 检测起始位
            rx_state <= RX_START;
            rx_break_detect <= 1;
          end
        end
        
        RX_START: begin
          rx_state <= RX_DATA;
          rx_bit_count <= 0;
        end
        
        RX_DATA: begin
          rx_shift <= {rx, rx_shift[7:1]}; // 移位寄存器操作
          if (rx) rx_break_detect <= 0;
          
          if (rx_bit_count == 3'b111) begin
            rx_state <= RX_STOP;
          end else begin
            rx_bit_count <= rx_bit_count + 3'b001;
          end
        end
        
        RX_STOP: begin
          rx_state <= RX_IDLE;
          
          if (rx) begin
            rx_data <= rx_shift;
            irq_rx_ready <= 1;
          end else begin
            frame_error <= 1;
            irq_frame_err <= 1;
          end
          
          if (rx_break_detect) begin
            irq_rx_break <= 1;
            rx_break_detect <= 0;
          end
        end
        
        default: rx_state <= RX_IDLE;
      endcase
    end
  end
  
  // TX处理逻辑
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      tx_state <= TX_IDLE;
      tx_bit_count <= 0;
      tx_shift <= 0;
      tx <= 1;
      irq_tx_done <= 0;
      clk_div_count <= 0;
    end else begin
      if (irq_tx_ack) irq_tx_done <= 0;
      
      // 分离时钟分频逻辑与状态机逻辑，提高可读性
      if (clk_div_count == CLK_DIV-1) begin
        clk_div_count <= 0;
        
        // 优化后的状态机 - 使用case结构
        case (tx_state)
          TX_IDLE: begin
            if (tx_start) begin
              tx_state <= TX_START;
              tx_shift <= tx_data;
            end
          end
          
          TX_START: begin
            tx <= 0;
            tx_state <= TX_DATA;
            tx_bit_count <= 0;
          end
          
          TX_DATA: begin
            tx <= tx_shift[0];
            tx_shift <= {1'b0, tx_shift[7:1]};
            
            if (tx_bit_count == 3'b111) begin
              tx_state <= TX_STOP;
            end else begin
              tx_bit_count <= tx_bit_count + 3'b001;
            end
          end
          
          TX_STOP: begin
            tx <= 1;
            tx_state <= TX_IDLE;
            irq_tx_done <= 1;
          end
          
          default: tx_state <= TX_IDLE;
        endcase
      end else begin
        clk_div_count <= clk_div_count + 1'b1;
      end
    end
  end
endmodule