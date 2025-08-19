module uart_loopback #(parameter DATA_WIDTH = 8) (
  input wire clk, rst_n,
  input wire rx_in,
  output wire tx_out,
  input wire [DATA_WIDTH-1:0] tx_data,
  input wire tx_valid,
  output reg tx_ready,
  output reg [DATA_WIDTH-1:0] rx_data,
  output reg rx_valid,
  input wire loopback_enable
);
  // Internal signals
  wire tx_to_rx;
  reg [1:0] tx_state, rx_state;
  reg [2:0] tx_bitpos, rx_bitpos;
  reg [DATA_WIDTH-1:0] tx_shift, rx_shift;
  reg tx_busy;
  reg tx_out_reg; // 添加寄存器
  
  // Loopback mux
  assign tx_to_rx = loopback_enable ? tx_out : rx_in;
  assign tx_out = tx_out_reg; // 连接输出
  
  // TX state machine
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state <= 0;
      tx_bitpos <= 0;
      tx_shift <= 0;
      tx_out_reg <= 1; // Idle high
      tx_ready <= 1;
      tx_busy <= 0;
    end else begin
      case (tx_state)
        0: begin // Idle
          if (tx_valid && tx_ready) begin
            tx_shift <= tx_data;
            tx_state <= 1;
            tx_ready <= 0;
            tx_busy <= 1;
          end
        end
        1: begin // Start bit
          tx_out_reg <= 0;
          tx_state <= 2;
          tx_bitpos <= 0;
        end
        2: begin // Data bits
          tx_out_reg <= tx_shift[0];
          tx_shift <= {1'b0, tx_shift[DATA_WIDTH-1:1]};
          if (tx_bitpos == DATA_WIDTH-1) tx_state <= 3;
          else tx_bitpos <= tx_bitpos + 1;
        end
        3: begin // Stop bit
          tx_out_reg <= 1;
          tx_state <= 0;
          tx_ready <= 1;
          tx_busy <= 0;
        end
        default: tx_state <= 0; // 添加默认状态
      endcase
    end
  end
  
  // RX state machine
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state <= 0;
      rx_bitpos <= 0;
      rx_shift <= 0;
      rx_data <= 0;
      rx_valid <= 0;
    end else begin
      case (rx_state)
        0: begin // Idle
          rx_valid <= 0;
          if (tx_to_rx == 0) rx_state <= 1; // Start bit
        end
        1: begin // Confirm start
          rx_state <= 2;
          rx_bitpos <= 0;
        end
        2: begin // Data bits
          rx_shift <= {tx_to_rx, rx_shift[DATA_WIDTH-1:1]};
          if (rx_bitpos == DATA_WIDTH-1) rx_state <= 3;
          else rx_bitpos <= rx_bitpos + 1;
        end
        3: begin // Stop bit
          if (tx_to_rx == 1) begin // Valid stop bit
            rx_data <= rx_shift;
            rx_valid <= 1;
          end
          rx_state <= 0;
        end
        default: rx_state <= 0; // 添加默认状态
      endcase
    end
  end
  
  // Test result comparison when in loopback mode
  reg [7:0] error_counter;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_counter <= 0;
    end else if (loopback_enable && rx_valid) begin
      // In loopback mode, compare transmitted and received data
      if (rx_data != tx_data && !error_counter[7]) begin
        error_counter <= error_counter + 1;
      end
    end
  end
endmodule