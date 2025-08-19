//SystemVerilog
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
  
  // State definitions - one-cold encoding (changed from one-hot)
  localparam SLEEP = 3'b110, AWAKE = 3'b101, ACTIVE = 3'b011;
  reg [2:0] power_state;
  
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
        default: power_state <= SLEEP;
      endcase
    end
  end
  
  // Edge detection for RX activity
  always @(posedge main_clk) begin
    rx_activity <= (rx_in == 0);
  end
  
  // TX state machine (runs on gated clock) - one-cold encoding (changed from one-hot)
  localparam TX_IDLE = 4'b1110, TX_START = 4'b1101, TX_DATA = 4'b1011, TX_STOP = 4'b0111;
  reg [3:0] tx_state;
  reg [3:0] tx_bit_idx;
  reg [DATA_BITS-1:0] tx_shift_reg;
  
  always @(posedge uart_clk or negedge reset_n) begin
    if (!reset_n) begin
      tx_state <= TX_IDLE;
      tx_bit_idx <= 0;
      tx_shift_reg <= 0;
      tx_out <= 1;
      tx_done <= 1;
    end else begin
      case (tx_state)
        TX_IDLE: begin
          if (tx_start) begin 
            tx_state <= TX_START; 
            tx_shift_reg <= tx_data; 
            tx_done <= 0; 
          end
        end
        TX_START: begin 
          tx_out <= 0; 
          tx_state <= TX_DATA; 
          tx_bit_idx <= 0; 
        end
        TX_DATA: begin
          tx_out <= tx_shift_reg[0];
          tx_shift_reg <= {1'b0, tx_shift_reg[DATA_BITS-1:1]};
          if (tx_bit_idx == DATA_BITS-1) 
            tx_state <= TX_STOP;
          else 
            tx_bit_idx <= tx_bit_idx + 1;
        end
        TX_STOP: begin 
          tx_out <= 1; 
          tx_state <= TX_IDLE; 
          tx_done <= 1; 
        end
        default: tx_state <= TX_IDLE;
      endcase
    end
  end
  
  // RX state machine (runs on gated clock) - one-cold encoding (changed from one-hot)
  localparam RX_IDLE = 4'b1110, RX_START = 4'b1101, RX_DATA = 4'b1011, RX_STOP = 4'b0111;
  reg [3:0] rx_state;
  reg [3:0] rx_bit_idx;
  reg [DATA_BITS-1:0] rx_shift_reg;
  
  always @(posedge uart_clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_state <= RX_IDLE;
      rx_bit_idx <= 0;
      rx_shift_reg <= 0;
      rx_data <= 0;
      rx_valid <= 0;
    end else begin
      case (rx_state)
        RX_IDLE: begin
          if (rx_in == 0) begin 
            rx_state <= RX_START; 
            rx_valid <= 0; 
          end
        end
        RX_START: begin 
          rx_state <= RX_DATA; 
          rx_bit_idx <= 0; 
        end
        RX_DATA: begin
          rx_shift_reg <= {rx_in, rx_shift_reg[DATA_BITS-1:1]};
          if (rx_bit_idx == DATA_BITS-1) 
            rx_state <= RX_STOP;
          else 
            rx_bit_idx <= rx_bit_idx + 1;
        end
        RX_STOP: begin
          if (rx_in == 1) begin // Valid stop bit
            rx_data <= rx_shift_reg;
            rx_valid <= 1;
          end
          rx_state <= RX_IDLE;
        end
        default: rx_state <= RX_IDLE;
      endcase
    end
  end
endmodule