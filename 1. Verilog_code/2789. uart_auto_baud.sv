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
          clk_counter <= clk_counter + 1;
          if (rx_prev == 0 && rx == 1) begin // Rising edge (start bit to first data bit)
            ab_state <= AB_MEASURE;
            baud_period <= clk_counter;
            clk_counter <= 0;
          end
        end
        AB_MEASURE: begin
          clk_counter <= clk_counter + 1;
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
          bit_timer <= bit_timer + 1;
          if (bit_timer >= baud_period/2) begin
            rx_state <= RX_DATA;
            bit_timer <= 0;
            bit_counter <= 0;
          end
        end
        RX_DATA: begin
          bit_timer <= bit_timer + 1;
          if (bit_timer >= baud_period) begin
            bit_timer <= 0;
            rx_data <= {rx, rx_data[7:1]};
            if (bit_counter == 7) rx_state <= RX_STOP;
            else bit_counter <= bit_counter + 1;
          end
        end
        RX_STOP: begin
          bit_timer <= bit_timer + 1;
          if (bit_timer >= baud_period) begin
            if (rx == 1) rx_valid <= 1; // Valid stop bit
            rx_state <= RX_IDLE;
          end
        end
      endcase
    end
  end
endmodule