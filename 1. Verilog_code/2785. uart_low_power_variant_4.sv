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
  
  // State definitions
  localparam SLEEP = 2'b00, AWAKE = 2'b01, ACTIVE = 2'b10;
  reg [1:0] power_state;
  
  // Activity detection and timing
  reg rx_activity;
  reg [7:0] idle_counter;
  
  // TX and RX state machine registers
  reg [1:0] tx_state;
  reg [3:0] tx_bit_idx;
  reg [DATA_BITS-1:0] tx_shift_reg;
  reg [1:0] rx_state;
  reg [3:0] rx_bit_idx;
  reg [DATA_BITS-1:0] rx_shift_reg;
  
  // Clock gating
  assign uart_clk = main_clk & clock_gate;
  
  // Power management signals
  reg wake_condition;
  reg reset_idle;
  reg sleep_condition;
  
  // TX state machine signals
  reg tx_start_bit;
  reg tx_data_bits;
  reg tx_stop_bit;
  reg tx_complete;
  
  // RX state machine signals
  reg rx_detect_start;
  reg rx_sample_bits;
  reg rx_check_stop;
  
  // Power management logic
  always @(posedge main_clk or negedge reset_n) begin
    if (!reset_n) begin
      power_state <= SLEEP;
      clock_gate <= 0;
      idle_counter <= 0;
      rx_activity <= 0;
    end else begin
      // Edge detection for RX activity
      rx_activity <= (rx_in == 0);
      
      // Intermediate signal calculation
      wake_condition = enable || (rx_in == 0) || tx_start;
      reset_idle = rx_activity || tx_start || !tx_done;
      sleep_condition = (idle_counter == 8'hFF) && !enable;
      
      // Power management state machine
      case (power_state)
        SLEEP: begin
          if (wake_condition) begin
            power_state <= AWAKE;
            clock_gate <= 1;
          end
        end
        
        AWAKE: begin
          power_state <= ACTIVE;
          idle_counter <= 0;
        end
        
        ACTIVE: begin
          if (reset_idle) begin
            idle_counter <= 0;
          end else begin
            idle_counter <= idle_counter + 1;
            if (sleep_condition) begin
              power_state <= SLEEP;
              clock_gate <= 0;
            end
          end
        end
        
        default: begin
          power_state <= SLEEP;
          clock_gate <= 0;
        end
      endcase
    end
  end
  
  // TX state machine logic
  always @(posedge uart_clk or negedge reset_n) begin
    if (!reset_n) begin
      tx_state <= 0;
      tx_bit_idx <= 0;
      tx_shift_reg <= 0;
      tx_out <= 1;
      tx_done <= 1;
    end else begin
      // Intermediate signal calculation
      tx_start_bit = (tx_state == 0) && tx_start;
      tx_data_bits = (tx_state == 2);
      tx_stop_bit = (tx_state == 3);
      tx_complete = (tx_state == 2) && (tx_bit_idx == DATA_BITS-1);
      
      // TX state transitions
      case (tx_state)
        0: begin
          if (tx_start_bit) begin 
            tx_state <= 1; 
            tx_shift_reg <= tx_data; 
            tx_done <= 0; 
          end
        end
        
        1: begin 
          tx_out <= 0; // Start bit
          tx_state <= 2; 
          tx_bit_idx <= 0; 
        end
        
        2: begin
          tx_out <= tx_shift_reg[0];
          tx_shift_reg <= {1'b0, tx_shift_reg[DATA_BITS-1:1]};
          
          if (tx_complete) begin
            tx_state <= 3;
          end else begin
            tx_bit_idx <= tx_bit_idx + 1;
          end
        end
        
        3: begin 
          tx_out <= 1; // Stop bit
          tx_state <= 0; 
          tx_done <= 1; 
        end
        
        default: begin
          tx_state <= 0;
          tx_out <= 1;
          tx_done <= 1;
        end
      endcase
    end
  end
  
  // RX state machine logic
  always @(posedge uart_clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_state <= 0;
      rx_bit_idx <= 0;
      rx_shift_reg <= 0;
      rx_data <= 0;
      rx_valid <= 0;
    end else begin
      // Intermediate signal calculation
      rx_detect_start = (rx_state == 0) && (rx_in == 0);
      rx_sample_bits = (rx_state == 2);
      rx_check_stop = (rx_state == 3);
      
      // RX state transitions
      case (rx_state)
        0: begin
          if (rx_detect_start) begin 
            rx_state <= 1; 
            rx_valid <= 0; 
          end
        end
        
        1: begin 
          rx_state <= 2; 
          rx_bit_idx <= 0; 
        end
        
        2: begin
          rx_shift_reg <= {rx_in, rx_shift_reg[DATA_BITS-1:1]};
          
          if (rx_bit_idx == DATA_BITS-1) begin
            rx_state <= 3;
          end else begin
            rx_bit_idx <= rx_bit_idx + 1;
          end
        end
        
        3: begin
          rx_state <= 0;
          
          if (rx_in == 1) begin // Valid stop bit
            rx_data <= rx_shift_reg;
            rx_valid <= 1;
          end
        end
        
        default: begin
          rx_state <= 0;
          rx_valid <= 0;
        end
      endcase
    end
  end
endmodule