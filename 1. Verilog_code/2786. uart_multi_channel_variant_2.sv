//SystemVerilog
module uart_multi_channel #(parameter CHANNELS = 4) (
  input wire clk, rst_n,
  input wire [CHANNELS-1:0] rx_in,
  output reg [CHANNELS-1:0] tx_out,
  input wire [7:0] tx_data [0:CHANNELS-1],
  input wire [CHANNELS-1:0] tx_valid,
  output reg [CHANNELS-1:0] tx_ready,
  output reg [7:0] rx_data [0:CHANNELS-1],
  output reg [CHANNELS-1:0] rx_valid,
  input wire [CHANNELS-1:0] rx_ready
);
  // Channel state tracking - one-hot encoded states
  // TX: 4 states - IDLE, START, DATA, STOP
  reg [3:0] tx_state [0:CHANNELS-1];
  // RX: 4 states - IDLE, START, DATA, STOP
  reg [3:0] rx_state [0:CHANNELS-1];
  
  // One-hot state encodings
  localparam [3:0] TX_IDLE  = 4'b0001;
  localparam [3:0] TX_START = 4'b0010;
  localparam [3:0] TX_DATA  = 4'b0100;
  localparam [3:0] TX_STOP  = 4'b1000;
  
  localparam [3:0] RX_IDLE  = 4'b0001;
  localparam [3:0] RX_START = 4'b0010;
  localparam [3:0] RX_DATA  = 4'b0100;
  localparam [3:0] RX_STOP  = 4'b1000;
  
  reg [2:0] tx_bit_count [0:CHANNELS-1];
  reg [2:0] rx_bit_count [0:CHANNELS-1];
  reg [7:0] tx_shift [0:CHANNELS-1];
  reg [7:0] rx_shift [0:CHANNELS-1];
  
  // 借位减法器相关信号
  reg [2:0] tx_bit_count_next [0:CHANNELS-1];
  reg [2:0] rx_bit_count_next [0:CHANNELS-1];
  reg borrow_tx [0:CHANNELS-1];
  reg borrow_rx [0:CHANNELS-1];
  reg [2:0] bit_count_target;
  
  genvar i;
  generate
    for (i = 0; i < CHANNELS; i = i + 1) begin : channel
      // TX state machine per channel
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          tx_state[i] <= TX_IDLE;
          tx_bit_count[i] <= 0;
          tx_shift[i] <= 0;
          tx_out[i] <= 1;
          tx_ready[i] <= 1;
        end else begin
          if (tx_state[i][0]) begin // Idle
            tx_out[i] <= 1;
            if (tx_valid[i] && tx_ready[i]) begin
              tx_state[i] <= TX_START;
              tx_shift[i] <= tx_data[i];
              tx_ready[i] <= 0;
            end
          end else if (tx_state[i][1]) begin // Start bit
            tx_out[i] <= 0;
            tx_state[i] <= TX_DATA;
            tx_bit_count[i] <= 0;
          end else if (tx_state[i][2]) begin // Data bits
            tx_out[i] <= tx_shift[i][0];
            tx_shift[i] <= {1'b0, tx_shift[i][7:1]};
            
            // 使用借位减法器算法检查是否发送完8位数据
            bit_count_target = 3'b111; // 目标值7
            {borrow_tx[i], tx_bit_count_next[i][0]} = {1'b0, tx_bit_count[i][0]} + {1'b0, 1'b1} - {1'b0, bit_count_target[0]};
            {borrow_tx[i], tx_bit_count_next[i][1]} = {1'b0, tx_bit_count[i][1]} + {1'b0, 1'b0} - {1'b0, bit_count_target[1]} - {1'b0, borrow_tx[i]};
            {borrow_tx[i], tx_bit_count_next[i][2]} = {1'b0, tx_bit_count[i][2]} + {1'b0, 1'b0} - {1'b0, bit_count_target[2]} - {1'b0, borrow_tx[i]};
            
            if (!borrow_tx[i]) // 如果没有借位，表示已经达到或超过目标值
              tx_state[i] <= TX_STOP;
            else 
              tx_bit_count[i] <= tx_bit_count[i] + 1;
          end else if (tx_state[i][3]) begin // Stop bit
            tx_out[i] <= 1;
            tx_state[i] <= TX_IDLE;
            tx_ready[i] <= 1;
          end else begin
            tx_state[i] <= TX_IDLE; // Safety default
          end
        end
      end
      
      // RX state machine per channel
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          rx_state[i] <= RX_IDLE;
          rx_bit_count[i] <= 0;
          rx_shift[i] <= 0;
          rx_data[i] <= 0;
          rx_valid[i] <= 0;
        end else begin
          // Clear valid flag when ready is asserted
          if (rx_valid[i] && rx_ready[i]) rx_valid[i] <= 0;
          
          if (rx_state[i][0]) begin // Idle
            if (rx_in[i] == 0) 
              rx_state[i] <= RX_START;
          end else if (rx_state[i][1]) begin // Start bit confirmed
            rx_state[i] <= RX_DATA; 
            rx_bit_count[i] <= 0;
          end else if (rx_state[i][2]) begin // Data bits
            rx_shift[i] <= {rx_in[i], rx_shift[i][7:1]};
            
            // 使用借位减法器算法检查是否接收完8位数据
            bit_count_target = 3'b111; // 目标值7
            {borrow_rx[i], rx_bit_count_next[i][0]} = {1'b0, rx_bit_count[i][0]} + {1'b0, 1'b1} - {1'b0, bit_count_target[0]};
            {borrow_rx[i], rx_bit_count_next[i][1]} = {1'b0, rx_bit_count[i][1]} + {1'b0, 1'b0} - {1'b0, bit_count_target[1]} - {1'b0, borrow_rx[i]};
            {borrow_rx[i], rx_bit_count_next[i][2]} = {1'b0, rx_bit_count[i][2]} + {1'b0, 1'b0} - {1'b0, bit_count_target[2]} - {1'b0, borrow_rx[i]};
            
            if (!borrow_rx[i]) // 如果没有借位，表示已经达到或超过目标值
              rx_state[i] <= RX_STOP;
            else
              rx_bit_count[i] <= rx_bit_count[i] + 1;
          end else if (rx_state[i][3]) begin // Stop bit
            rx_state[i] <= RX_IDLE;
            if (rx_in[i] == 1 && !rx_valid[i]) begin
              rx_data[i] <= rx_shift[i];
              rx_valid[i] <= 1;
            end
          end else begin
            rx_state[i] <= RX_IDLE; // Safety default
          end
        end
      end
    end
  endgenerate
endmodule