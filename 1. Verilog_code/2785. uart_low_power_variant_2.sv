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
  
  // State definitions using one-hot encoding
  localparam SLEEP = 3'b001, AWAKE = 3'b010, ACTIVE = 3'b100;
  reg [2:0] power_state;
  
  // Activity detection and timing
  reg rx_activity;
  reg [7:0] idle_counter;
  
  // Look-ahead carry adder signals for idle_counter increment
  wire [7:0] carry_gen; // Generate signals
  wire [7:0] carry_prop; // Propagate signals  
  wire [8:0] carries; // Carry signals including initial carry-in
  
  // Clock gating
  assign uart_clk = main_clk & clock_gate;
  
  // Generate and propagate signals for look-ahead incrementer
  assign carry_gen = 8'b0; // For increment, all generate terms are 0
  assign carry_prop = idle_counter; // For increment, propagate = input bit
  
  // Carry chain calculation using look-ahead logic
  assign carries[0] = 1'b1; // Carry-in for increment operation is 1
  assign carries[1] = carry_prop[0] & carries[0];
  assign carries[2] = carry_prop[1] & carries[1];
  assign carries[3] = carry_prop[2] & carries[2];
  assign carries[4] = carry_prop[3] & carries[3];
  assign carries[5] = carry_prop[4] & carries[4];
  assign carries[6] = carry_prop[5] & carries[5];
  assign carries[7] = carry_prop[6] & carries[6];
  assign carries[8] = carry_prop[7] & carries[7];
  
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
            // Look-ahead incrementer implementation (replacing idle_counter <= idle_counter + 1)
            idle_counter[0] <= ~idle_counter[0];
            idle_counter[1] <= idle_counter[1] ^ carries[1];
            idle_counter[2] <= idle_counter[2] ^ carries[2];
            idle_counter[3] <= idle_counter[3] ^ carries[3];
            idle_counter[4] <= idle_counter[4] ^ carries[4];
            idle_counter[5] <= idle_counter[5] ^ carries[5];
            idle_counter[6] <= idle_counter[6] ^ carries[6];
            idle_counter[7] <= idle_counter[7] ^ carries[7];
            
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
  
  // TX state machine (runs on gated clock) with one-hot encoding
  localparam TX_IDLE = 4'b0001, TX_START = 4'b0010, TX_DATA = 4'b0100, TX_STOP = 4'b1000;
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
        TX_IDLE: 
          if (tx_start) begin 
            tx_state <= TX_START; 
            tx_shift_reg <= tx_data; 
            tx_done <= 0; 
          end
        TX_START: begin 
          tx_out <= 0; 
          tx_state <= TX_DATA; 
          tx_bit_idx <= 0; 
        end // Start bit
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
        end // Stop bit
        default: tx_state <= TX_IDLE;
      endcase
    end
  end
  
  // RX state machine (runs on gated clock) with one-hot encoding
  localparam RX_IDLE = 4'b0001, RX_START = 4'b0010, RX_DATA = 4'b0100, RX_STOP = 4'b1000;
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
        RX_IDLE: 
          if (rx_in == 0) begin 
            rx_state <= RX_START; 
            rx_valid <= 0; 
          end
        RX_START: begin 
          rx_state <= RX_DATA; 
          rx_bit_idx <= 0; 
        end // Confirm start bit
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