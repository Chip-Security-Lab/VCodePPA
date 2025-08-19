module uart_full_duplex (
  input wire clk, rst_n,
  input wire rx_in,
  output wire tx_out,
  input wire [7:0] tx_data,
  input wire tx_start,
  output reg tx_busy,
  output reg [7:0] rx_data,
  output reg rx_ready,
  output reg rx_error
);
  // TX state machine
  localparam TX_IDLE = 2'b00, TX_START = 2'b01, TX_DATA = 2'b10, TX_STOP = 2'b11;
  reg [1:0] tx_state;
  reg [2:0] tx_bit_pos;
  reg [7:0] tx_shift_reg;
  reg tx_out_reg; // 添加寄存器
  
  // RX state machine
  localparam RX_IDLE = 2'b00, RX_START = 2'b01, RX_DATA = 2'b10, RX_STOP = 2'b11;
  reg [1:0] rx_state;
  reg [2:0] rx_bit_pos;
  reg [7:0] rx_shift_reg;
  
  // Baud rate control
  reg [7:0] baud_count_tx, baud_count_rx;
  wire baud_tick_tx, baud_tick_rx;
  
  assign baud_tick_tx = (baud_count_tx == 8'd104); // For 9600 baud @ 1MHz
  assign baud_tick_rx = (baud_count_rx == 8'd26);  // 4x oversampling
  assign tx_out = tx_out_reg; // 连接输出信号
  
  // TX logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state <= TX_IDLE;
      tx_out_reg <= 1'b1;
      tx_busy <= 1'b0;
      tx_bit_pos <= 0;
      tx_shift_reg <= 0;
      baud_count_tx <= 0;
    end else begin
      if (baud_count_tx == 8'd104) baud_count_tx <= 0;
      else baud_count_tx <= baud_count_tx + 1;
      
      if (baud_tick_tx) begin
        case (tx_state)
          TX_IDLE: if (tx_start) begin
            tx_state <= TX_START;
            tx_shift_reg <= tx_data;
            tx_busy <= 1'b1;
          end
          TX_START: begin
            tx_out_reg <= 1'b0;
            tx_state <= TX_DATA;
            tx_bit_pos <= 0;
          end
          TX_DATA: begin
            tx_out_reg <= tx_shift_reg[0];
            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
            if (tx_bit_pos == 7) tx_state <= TX_STOP;
            else tx_bit_pos <= tx_bit_pos + 1;
          end
          TX_STOP: begin
            tx_out_reg <= 1'b1;
            tx_state <= TX_IDLE;
            tx_busy <= 1'b0;
          end
          default: tx_state <= TX_IDLE; // 添加默认状态
        endcase
      end
    end
  end
  
  // RX logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state <= RX_IDLE;
      rx_bit_pos <= 0;
      rx_shift_reg <= 0;
      rx_ready <= 0;
      rx_error <= 0;
      baud_count_rx <= 0;
      rx_data <= 0; // 初始化数据寄存器
    end else begin
      if (baud_count_rx == 8'd26) baud_count_rx <= 0;
      else baud_count_rx <= baud_count_rx + 1;
      
      if (baud_tick_rx) begin
        case (rx_state)
          RX_IDLE: if (rx_in == 0) begin
            rx_state <= RX_START;
            rx_ready <= 0;
          end
          RX_START: rx_state <= RX_DATA;
          RX_DATA: begin
            rx_shift_reg <= {rx_in, rx_shift_reg[7:1]};
            if (rx_bit_pos == 7) rx_state <= RX_STOP;
            else rx_bit_pos <= rx_bit_pos + 1;
          end
          RX_STOP: begin
            if (rx_in == 1) begin
              rx_data <= rx_shift_reg;
              rx_ready <= 1;
              rx_error <= 0;
            end else rx_error <= 1;
            rx_state <= RX_IDLE;
          end
          default: rx_state <= RX_IDLE; // 添加默认状态
        endcase
      end
    end
  end
endmodule