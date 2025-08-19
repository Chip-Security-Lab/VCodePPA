//SystemVerilog
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
  reg tx_out_reg;
  
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
  assign tx_out = tx_out_reg;
  
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
      // 扁平化计数器更新逻辑
      baud_count_tx <= (baud_count_tx == 8'd104) ? 8'd0 : baud_count_tx + 1'b1;
      
      // 扁平化状态机逻辑
      if (baud_tick_tx && tx_state == TX_IDLE && tx_start) begin
        tx_state <= TX_START;
        tx_shift_reg <= tx_data;
        tx_busy <= 1'b1;
      end else if (baud_tick_tx && tx_state == TX_START) begin
        tx_out_reg <= 1'b0;
        tx_state <= TX_DATA;
        tx_bit_pos <= 0;
      end else if (baud_tick_tx && tx_state == TX_DATA) begin
        tx_out_reg <= tx_shift_reg[0];
        tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
        if (tx_bit_pos == 7) 
          tx_state <= TX_STOP;
        else 
          tx_bit_pos <= tx_bit_pos + 1'b1;
      end else if (baud_tick_tx && tx_state == TX_STOP) begin
        tx_out_reg <= 1'b1;
        tx_state <= TX_IDLE;
        tx_busy <= 1'b0;
      end else if (baud_tick_tx) begin
        tx_state <= TX_IDLE; // 默认情况
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
      rx_data <= 0;
    end else begin
      // 扁平化计数器更新逻辑
      baud_count_rx <= (baud_count_rx == 8'd26) ? 8'd0 : baud_count_rx + 1'b1;
      
      // 扁平化状态机逻辑
      if (baud_tick_rx && rx_state == RX_IDLE && rx_in == 0) begin
        rx_state <= RX_START;
        rx_ready <= 0;
      end else if (baud_tick_rx && rx_state == RX_START) begin
        rx_state <= RX_DATA;
        rx_bit_pos <= 0; // 明确初始化位置计数器
      end else if (baud_tick_rx && rx_state == RX_DATA) begin
        rx_shift_reg <= {rx_in, rx_shift_reg[7:1]};
        if (rx_bit_pos == 7)
          rx_state <= RX_STOP;
        else
          rx_bit_pos <= rx_bit_pos + 1'b1;
      end else if (baud_tick_rx && rx_state == RX_STOP) begin
        if (rx_in == 1) begin
          rx_data <= rx_shift_reg;
          rx_ready <= 1;
          rx_error <= 0;
        end else begin
          rx_error <= 1;
        end
        rx_state <= RX_IDLE;
      end else if (baud_tick_rx) begin
        rx_state <= RX_IDLE; // 默认情况
      end
    end
  end
endmodule