//SystemVerilog
module uart_auto_baud (
  input wire clk, reset_n,
  input wire rx,
  output reg [7:0] rx_data,
  output reg rx_valid,
  output reg [15:0] detected_baud
);
  // Auto-baud detection states
  localparam AB_IDLE = 0, AB_START = 1, AB_MEASURE = 2, AB_LOCK = 3;
  // UART receive states
  localparam RX_IDLE = 0, RX_START = 1, RX_DATA = 2, RX_STOP = 3;
  
  reg [1:0] ab_state;  // Auto-baud state
  reg [1:0] rx_state;  // Receiver state
  reg rx_prev;        // Previous RX value for edge detection
  
  reg [15:0] clk_counter;  // Clock counter for edge timing
  reg [15:0] baud_period;  // Measured baud period
  reg [15:0] bit_timer;    // Bit timing counter
  reg [2:0] bit_counter;   // Bit position counter
  
  // Manchester Carry Chain Adder signals
  wire [15:0] p_signals, g_signals;
  wire [15:0] carry_chain;
  wire [15:0] next_clk_counter, next_bit_timer;
  
  // Generate propagate and generate signals for Manchester carry chain
  assign p_signals = clk_counter;
  assign g_signals = 16'h0001; // Add 1
  
  // Manchester carry chain implementation
  assign carry_chain[0] = g_signals[0];
  assign carry_chain[1] = g_signals[1] | (p_signals[1] & carry_chain[0]);
  assign carry_chain[2] = g_signals[2] | (p_signals[2] & carry_chain[1]);
  assign carry_chain[3] = g_signals[3] | (p_signals[3] & carry_chain[2]);
  assign carry_chain[4] = g_signals[4] | (p_signals[4] & carry_chain[3]);
  assign carry_chain[5] = g_signals[5] | (p_signals[5] & carry_chain[4]);
  assign carry_chain[6] = g_signals[6] | (p_signals[6] & carry_chain[5]);
  assign carry_chain[7] = g_signals[7] | (p_signals[7] & carry_chain[6]);
  assign carry_chain[8] = g_signals[8] | (p_signals[8] & carry_chain[7]);
  assign carry_chain[9] = g_signals[9] | (p_signals[9] & carry_chain[8]);
  assign carry_chain[10] = g_signals[10] | (p_signals[10] & carry_chain[9]);
  assign carry_chain[11] = g_signals[11] | (p_signals[11] & carry_chain[10]);
  assign carry_chain[12] = g_signals[12] | (p_signals[12] & carry_chain[11]);
  assign carry_chain[13] = g_signals[13] | (p_signals[13] & carry_chain[12]);
  assign carry_chain[14] = g_signals[14] | (p_signals[14] & carry_chain[13]);
  assign carry_chain[15] = g_signals[15] | (p_signals[15] & carry_chain[14]);
  
  // Final sum calculation
  assign next_clk_counter = p_signals ^ {carry_chain[14:0], 1'b0};
  
  // Manchester carry chain for bit_timer
  wire [15:0] p_signals_bit, g_signals_bit;
  wire [15:0] carry_chain_bit;
  
  // Generate propagate and generate signals for bit_timer
  assign p_signals_bit = bit_timer;
  assign g_signals_bit = 16'h0001; // Add 1
  
  // Manchester carry chain implementation for bit_timer
  assign carry_chain_bit[0] = g_signals_bit[0];
  assign carry_chain_bit[1] = g_signals_bit[1] | (p_signals_bit[1] & carry_chain_bit[0]);
  assign carry_chain_bit[2] = g_signals_bit[2] | (p_signals_bit[2] & carry_chain_bit[1]);
  assign carry_chain_bit[3] = g_signals_bit[3] | (p_signals_bit[3] & carry_chain_bit[2]);
  assign carry_chain_bit[4] = g_signals_bit[4] | (p_signals_bit[4] & carry_chain_bit[3]);
  assign carry_chain_bit[5] = g_signals_bit[5] | (p_signals_bit[5] & carry_chain_bit[4]);
  assign carry_chain_bit[6] = g_signals_bit[6] | (p_signals_bit[6] & carry_chain_bit[5]);
  assign carry_chain_bit[7] = g_signals_bit[7] | (p_signals_bit[7] & carry_chain_bit[6]);
  assign carry_chain_bit[8] = g_signals_bit[8] | (p_signals_bit[8] & carry_chain_bit[7]);
  assign carry_chain_bit[9] = g_signals_bit[9] | (p_signals_bit[9] & carry_chain_bit[8]);
  assign carry_chain_bit[10] = g_signals_bit[10] | (p_signals_bit[10] & carry_chain_bit[9]);
  assign carry_chain_bit[11] = g_signals_bit[11] | (p_signals_bit[11] & carry_chain_bit[10]);
  assign carry_chain_bit[12] = g_signals_bit[12] | (p_signals_bit[12] & carry_chain_bit[11]);
  assign carry_chain_bit[13] = g_signals_bit[13] | (p_signals_bit[13] & carry_chain_bit[12]);
  assign carry_chain_bit[14] = g_signals_bit[14] | (p_signals_bit[14] & carry_chain_bit[13]);
  assign carry_chain_bit[15] = g_signals_bit[15] | (p_signals_bit[15] & carry_chain_bit[14]);
  
  // Final sum calculation for bit_timer
  assign next_bit_timer = p_signals_bit ^ {carry_chain_bit[14:0], 1'b0};
  
  // Auto-baud detection looks for 0x55 (U) character
  // which has 10101010 pattern (alternating edges)
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ab_state <= AB_IDLE;
      clk_counter <= 0;
      baud_period <= 0;
      detected_baud <= 0;
      rx_prev <= 1;
    end else begin
      rx_prev <= rx;
      
      case (ab_state)
        AB_IDLE: begin
          if (rx_prev == 1 && rx == 0) begin // Falling edge (start of start bit)
            ab_state <= AB_START;
            clk_counter <= 0;
          end
        end
        AB_START: begin
          clk_counter <= next_clk_counter;
          if (rx_prev == 0 && rx == 1) begin // Rising edge (start bit to first data bit)
            ab_state <= AB_MEASURE;
            baud_period <= clk_counter;
            clk_counter <= 0;
          end
        end
        AB_MEASURE: begin
          clk_counter <= next_clk_counter;
          if (rx_prev != rx) begin // Edge detected
            if (clk_counter >= baud_period/2) begin
              // Confirm measurement based on multiple edges
              ab_state <= AB_LOCK;
              detected_baud <= (16'd50_000_000 / baud_period); // Assuming 50MHz clock
            end
            clk_counter <= 0;
          end
        end
        AB_LOCK: begin
          // Auto-baud locked, no further adjustments
        end
      endcase
    end
  end
  
  // UART receiver using the detected baud rate
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_state <= RX_IDLE;
      bit_timer <= 0;
      bit_counter <= 0;
      rx_data <= 0;
      rx_valid <= 0;
    end else if (ab_state == AB_LOCK) begin
      case (rx_state)
        RX_IDLE: begin
          rx_valid <= 0;
          if (rx == 0) begin // Start bit
            rx_state <= RX_START;
            bit_timer <= 0;
          end
        end
        RX_START: begin
          bit_timer <= next_bit_timer;
          if (bit_timer >= baud_period/2) begin
            rx_state <= RX_DATA;
            bit_timer <= 0;
            bit_counter <= 0;
          end
        end
        RX_DATA: begin
          bit_timer <= next_bit_timer;
          if (bit_timer >= baud_period) begin
            bit_timer <= 0;
            rx_data <= {rx, rx_data[7:1]};
            if (bit_counter == 7) rx_state <= RX_STOP;
            else bit_counter <= bit_counter + 1;
          end
        end
        RX_STOP: begin
          bit_timer <= next_bit_timer;
          if (bit_timer >= baud_period) begin
            if (rx == 1) rx_valid <= 1; // Valid stop bit
            rx_state <= RX_IDLE;
          end
        end
      endcase
    end
  end
endmodule