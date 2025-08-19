//SystemVerilog
module uart_interrupt #(
  parameter CLK_DIV = 16
) (
  input  wire        clock,
  input  wire        reset_n,
  input  wire        rx,
  output wire        tx,
  input  wire [7:0]  tx_data,
  input  wire        tx_start,
  output wire [7:0]  rx_data,
  output wire        irq_tx_done,
  output wire        irq_rx_ready,
  output wire        irq_rx_break,
  output wire        irq_frame_err,
  input  wire        irq_tx_ack,
  input  wire        irq_rx_ack,
  input  wire        irq_break_ack,
  input  wire        irq_frame_ack
);
  // 顶层模块实例化接收器和发送器子模块
  uart_receiver #(
    .CLK_DIV(CLK_DIV)
  ) receiver_inst (
    .clock        (clock),
    .reset_n      (reset_n),
    .rx           (rx),
    .rx_data      (rx_data),
    .irq_rx_ready (irq_rx_ready),
    .irq_rx_break (irq_rx_break),
    .irq_frame_err(irq_frame_err),
    .irq_rx_ack   (irq_rx_ack),
    .irq_break_ack(irq_break_ack),
    .irq_frame_ack(irq_frame_ack)
  );
  
  uart_transmitter #(
    .CLK_DIV(CLK_DIV)
  ) transmitter_inst (
    .clock      (clock),
    .reset_n    (reset_n),
    .tx         (tx),
    .tx_data    (tx_data),
    .tx_start   (tx_start),
    .irq_tx_done(irq_tx_done),
    .irq_tx_ack (irq_tx_ack)
  );
endmodule

module uart_receiver #(
  parameter CLK_DIV = 16
) (
  input  wire        clock,
  input  wire        reset_n,
  input  wire        rx,
  output reg  [7:0]  rx_data,
  output reg         irq_rx_ready,
  output reg         irq_rx_break,
  output reg         irq_frame_err,
  input  wire        irq_rx_ack,
  input  wire        irq_break_ack,
  input  wire        irq_frame_ack
);
  // 内部连接信号
  wire       clk_div_pulse;
  wire       rx_data_ready;
  wire       frame_error;
  wire       break_detected;
  wire [7:0] rx_shift_data;

  // 实例化子模块
  rx_baud_generator #(
    .CLK_DIV(CLK_DIV)
  ) rx_baud_gen (
    .clock        (clock),
    .reset_n      (reset_n),
    .clk_div_pulse(clk_div_pulse)
  );
  
  rx_state_controller rx_state_ctrl (
    .clock         (clock),
    .reset_n       (reset_n),
    .rx            (rx),
    .clk_div_pulse (clk_div_pulse),
    .rx_shift_data (rx_shift_data),
    .rx_data_ready (rx_data_ready),
    .frame_error   (frame_error),
    .break_detected(break_detected)
  );
  
  rx_interrupt_controller rx_irq_ctrl (
    .clock         (clock),
    .reset_n       (reset_n),
    .rx_data_ready (rx_data_ready),
    .frame_error   (frame_error),
    .break_detected(break_detected),
    .rx_shift_data (rx_shift_data),
    .irq_rx_ack    (irq_rx_ack),
    .irq_break_ack (irq_break_ack),
    .irq_frame_ack (irq_frame_ack),
    .rx_data       (rx_data),
    .irq_rx_ready  (irq_rx_ready),
    .irq_rx_break  (irq_rx_break),
    .irq_frame_err (irq_frame_err)
  );
endmodule

module rx_baud_generator #(
  parameter CLK_DIV = 16
) (
  input  wire clock,
  input  wire reset_n,
  output wire clk_div_pulse
);
  reg [7:0] clk_div_count;
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      clk_div_count <= 0;
    end else begin
      if (clk_div_count == CLK_DIV-1)
        clk_div_count <= 0;
      else
        clk_div_count <= clk_div_count + 1;
    end
  end
  
  assign clk_div_pulse = (clk_div_count == CLK_DIV-1);
endmodule

module rx_state_controller (
  input  wire        clock,
  input  wire        reset_n,
  input  wire        rx,
  input  wire        clk_div_pulse,
  output reg  [7:0]  rx_shift_data,
  output reg         rx_data_ready,
  output reg         frame_error,
  output reg         break_detected
);
  // 接收状态定义
  localparam RX_IDLE = 0, RX_START = 1, RX_DATA = 2, RX_STOP = 3;
  
  reg [1:0] rx_state;
  reg [3:0] rx_bit_count;
  reg       rx_break_detect;
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      rx_state       <= RX_IDLE;
      rx_bit_count   <= 0;
      rx_shift_data  <= 0;
      rx_data_ready  <= 0;
      frame_error    <= 0;
      rx_break_detect <= 0;
      break_detected <= 0;
    end else begin
      // 默认状态
      rx_data_ready  <= 0;
      frame_error    <= 0;
      break_detected <= 0;
      
      if (clk_div_pulse) begin
        case (rx_state)
          RX_IDLE: 
            if (rx == 0) begin 
              rx_state <= RX_START; 
              rx_break_detect <= 1; 
            end
          
          RX_START: begin 
            rx_state <= RX_DATA; 
            rx_bit_count <= 0; 
          end
          
          RX_DATA: begin
            rx_shift_data <= {rx, rx_shift_data[7:1]};
            if (rx == 1) rx_break_detect <= 0;
            if (rx_bit_count == 7) begin
              rx_state <= RX_STOP;
            end else rx_bit_count <= rx_bit_count + 1;
          end
          
          RX_STOP: begin
            rx_state <= RX_IDLE;
            if (rx == 0) begin
              frame_error <= 1;
            end else begin
              rx_data_ready <= 1;
            end
            if (rx_break_detect) begin
              break_detected <= 1;
              rx_break_detect <= 0;
            end
          end
          
          default: rx_state <= RX_IDLE;
        endcase
      end
    end
  end
endmodule

module rx_interrupt_controller (
  input  wire        clock,
  input  wire        reset_n,
  input  wire        rx_data_ready,
  input  wire        frame_error,
  input  wire        break_detected,
  input  wire [7:0]  rx_shift_data,
  input  wire        irq_rx_ack,
  input  wire        irq_break_ack,
  input  wire        irq_frame_ack,
  output reg  [7:0]  rx_data,
  output reg         irq_rx_ready,
  output reg         irq_rx_break,
  output reg         irq_frame_err
);
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      rx_data      <= 0;
      irq_rx_ready <= 0;
      irq_rx_break <= 0;
      irq_frame_err <= 0;
    end else begin
      // 中断确认处理
      if (irq_rx_ack)   irq_rx_ready <= 0;
      if (irq_break_ack) irq_rx_break <= 0;
      if (irq_frame_ack) irq_frame_err <= 0;
      
      // 中断产生
      if (rx_data_ready) begin
        rx_data <= rx_shift_data;
        irq_rx_ready <= 1;
      end
      
      if (frame_error) begin
        irq_frame_err <= 1;
      end
      
      if (break_detected) begin
        irq_rx_break <= 1;
      end
    end
  end
endmodule

module uart_transmitter #(
  parameter CLK_DIV = 16
) (
  input  wire        clock,
  input  wire        reset_n,
  output wire        tx,
  input  wire [7:0]  tx_data,
  input  wire        tx_start,
  output wire        irq_tx_done,
  input  wire        irq_tx_ack
);
  // 内部连接信号
  wire       clk_div_pulse;
  wire       tx_complete;
  wire       tx_bit;

  // 实例化子模块
  tx_baud_generator #(
    .CLK_DIV(CLK_DIV)
  ) tx_baud_gen (
    .clock        (clock),
    .reset_n      (reset_n),
    .clk_div_pulse(clk_div_pulse)
  );
  
  tx_state_controller tx_state_ctrl (
    .clock        (clock),
    .reset_n      (reset_n),
    .tx_data      (tx_data),
    .tx_start     (tx_start),
    .clk_div_pulse(clk_div_pulse),
    .tx_bit       (tx_bit),
    .tx_complete  (tx_complete)
  );
  
  tx_interrupt_controller tx_irq_ctrl (
    .clock      (clock),
    .reset_n    (reset_n),
    .tx_complete(tx_complete),
    .irq_tx_ack (irq_tx_ack),
    .irq_tx_done(irq_tx_done)
  );
  
  assign tx = tx_bit;
endmodule

module tx_baud_generator #(
  parameter CLK_DIV = 16
) (
  input  wire clock,
  input  wire reset_n,
  output wire clk_div_pulse
);
  reg [7:0] clk_div_count;
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      clk_div_count <= 0;
    end else begin
      if (clk_div_count == CLK_DIV-1)
        clk_div_count <= 0;
      else
        clk_div_count <= clk_div_count + 1;
    end
  end
  
  assign clk_div_pulse = (clk_div_count == CLK_DIV-1);
endmodule

module tx_state_controller (
  input  wire        clock,
  input  wire        reset_n,
  input  wire [7:0]  tx_data,
  input  wire        tx_start,
  input  wire        clk_div_pulse,
  output reg         tx_bit,
  output reg         tx_complete
);
  // 发送状态定义
  localparam TX_IDLE = 0, TX_START = 1, TX_DATA = 2, TX_STOP = 3;
  
  reg [1:0] tx_state;
  reg [7:0] tx_shift;
  reg [3:0] tx_bit_count;
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      tx_state     <= TX_IDLE;
      tx_bit_count <= 0;
      tx_shift     <= 0;
      tx_bit       <= 1;  // 空闲状态下保持高电平
      tx_complete  <= 0;
    end else begin
      // 默认状态
      tx_complete <= 0;
      
      if (clk_div_pulse) begin
        case (tx_state)
          TX_IDLE: 
            if (tx_start) begin
              tx_state <= TX_START;
              tx_shift <= tx_data;
            end
          
          TX_START: begin
            tx_bit <= 0;  // 起始位为低电平
            tx_state <= TX_DATA;
            tx_bit_count <= 0;
          end
          
          TX_DATA: begin
            tx_bit <= tx_shift[0];
            tx_shift <= {1'b0, tx_shift[7:1]};
            if (tx_bit_count == 7) 
              tx_state <= TX_STOP;
            else 
              tx_bit_count <= tx_bit_count + 1;
          end
          
          TX_STOP: begin
            tx_bit <= 1;  // 停止位为高电平
            tx_state <= TX_IDLE;
            tx_complete <= 1;
          end
          
          default: tx_state <= TX_IDLE;
        endcase
      end
    end
  end
endmodule

module tx_interrupt_controller (
  input  wire clock,
  input  wire reset_n,
  input  wire tx_complete,
  input  wire irq_tx_ack,
  output reg  irq_tx_done
);
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      irq_tx_done <= 0;
    end else begin
      // 中断确认处理
      if (irq_tx_ack) 
        irq_tx_done <= 0;
      
      // 中断产生
      if (tx_complete)
        irq_tx_done <= 1;
    end
  end
endmodule