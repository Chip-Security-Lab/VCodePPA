module uart_low_power #(parameter DATA_BITS = 8) (
  input wire main_clk, enable, reset_n,
  input wire rx_in,
  output reg tx_out,
  input wire tx_start,
  input wire [DATA_BITS-1:0] tx_data,
  output reg [DATA_BITS-1:0] rx_data,
  output reg rx_valid, tx_done
);
  // Clock gating signal
  wire uart_clk;
  reg clock_gate;
  
  // State definitions
  localparam SLEEP = 2'b00, AWAKE = 2'b01, ACTIVE = 2'b10;
  reg [1:0] power_state;
  
  // Activity detection and timing
  reg rx_activity;
  reg [7:0] idle_counter;
  
  // Clock gating
  assign uart_clk = main_clk & clock_gate;
  
  // Power management state machine
  always @(posedge main_clk or negedge reset_n) begin
    if (!reset_n) begin
      power_state <= SLEEP;
      clock_gate <= 0;
      idle_counter <= 0;
    end else begin
      case (power_state)
        SLEEP: begin
          if (enable || rx_in == 0 || tx_start) begin
            power_state <= AWAKE;
            clock_gate <= 1;
          end
        end
        AWAKE: begin
          power_state <= ACTIVE;
          idle_counter <= 0;
        end
        ACTIVE: begin
          if (rx_activity || tx_start || !tx_done) begin
            idle_counter <= 0;
          end else begin
            idle_counter <= idle_counter + 1;
            if (idle_counter == 8'hFF && !enable) begin
              power_state <= SLEEP;
              clock_gate <= 0;
            end
          end
        end
      endcase
    end
  end
  
  // Edge detection for RX activity
  always @(posedge main_clk) begin
    rx_activity <= (rx_in == 0);
  end
  
  // TX state machine (runs on gated clock)
  reg [1:0] tx_state;
  reg [3:0] tx_bit_idx;
  reg [DATA_BITS-1:0] tx_shift_reg;
  
  always @(posedge uart_clk or negedge reset_n) begin
    if (!reset_n) begin
      tx_state <= 0;
      tx_bit_idx <= 0;
      tx_shift_reg <= 0;
      tx_out <= 1;
      tx_done <= 1;
    end else begin
      case (tx_state)
        0: if (tx_start) begin tx_state <= 1; tx_shift_reg <= tx_data; tx_done <= 0; end
        1: begin tx_out <= 0; tx_state <= 2; tx_bit_idx <= 0; end // Start bit
        2: begin
          tx_out <= tx_shift_reg[0];
          tx_shift_reg <= {1'b0, tx_shift_reg[DATA_BITS-1:1]};
          if (tx_bit_idx == DATA_BITS-1) tx_state <= 3;
          else tx_bit_idx <= tx_bit_idx + 1;
        end
        3: begin tx_out <= 1; tx_state <= 0; tx_done <= 1; end // Stop bit
      endcase
    end
  end
  
  // RX state machine (runs on gated clock)
  reg [1:0] rx_state;
  reg [3:0] rx_bit_idx;
  reg [DATA_BITS-1:0] rx_shift_reg;
  
  always @(posedge uart_clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_state <= 0;
      rx_bit_idx <= 0;
      rx_shift_reg <= 0;
      rx_data <= 0;
      rx_valid <= 0;
    end else begin
      case (rx_state)
        0: if (rx_in == 0) begin rx_state <= 1; rx_valid <= 0; end
        1: begin rx_state <= 2; rx_bit_idx <= 0; end // Confirm start bit
        2: begin
          rx_shift_reg <= {rx_in, rx_shift_reg[DATA_BITS-1:1]};
          if (rx_bit_idx == DATA_BITS-1) rx_state <= 3;
          else rx_bit_idx <= rx_bit_idx + 1;
        end
        3: begin
          if (rx_in == 1) begin // Valid stop bit
            rx_data <= rx_shift_reg;
            rx_valid <= 1;
          end
          rx_state <= 0;
        end
      endcase
    end
  end
endmodule