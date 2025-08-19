//SystemVerilog
module uart_break_detect (
  input wire clock,
  input wire reset_n,
  input wire rx_in,
  
  // Valid-Ready接口
  output reg [7:0] rx_data,
  output reg rx_valid,
  input wire rx_ready,
  
  output reg break_detect,
  output reg break_valid,
  input wire break_ready
);
  // States
  localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, BREAK = 4, WAIT_READY = 5;
  reg [2:0] state, next_state;
  
  // Counters
  reg [2:0] bit_counter, next_bit_counter;
  reg [3:0] break_counter, next_break_counter; // Count consecutive zeros
  
  // Data registers
  reg [7:0] rx_data_reg, next_rx_data_reg;
  reg break_detect_reg, next_break_detect_reg;
  
  // UART parameters
  localparam BREAK_THRESHOLD = 10; // Number of bits to detect break

  // State reset and register update logic
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      bit_counter <= 0;
      break_counter <= 0;
      rx_data_reg <= 0;
      break_detect_reg <= 0;
    end else begin
      state <= next_state;
      bit_counter <= next_bit_counter;
      break_counter <= next_break_counter;
      rx_data_reg <= next_rx_data_reg;
      break_detect_reg <= next_break_detect_reg;
    end
  end

  // Output registers update logic
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      rx_data <= 0;
      rx_valid <= 0;
      break_detect <= 0;
      break_valid <= 0;
    end else begin
      // Default values for valid signals
      if (rx_valid && rx_ready) rx_valid <= 0;
      if (break_valid && break_ready) break_valid <= 0;
      
      // Set data output when transitioning to WAIT_READY from STOP
      if (state == STOP && next_state == WAIT_READY && rx_in == 1) begin
        rx_data <= rx_data_reg;
        rx_valid <= 1;
      end
      
      // Set break detect output when transitioning to WAIT_READY from BREAK
      if (state == BREAK && next_state == WAIT_READY) begin
        break_detect <= break_detect_reg;
        break_valid <= 1;
      end
    end
  end

  // Next state and internal registers logic
  always @(*) begin
    // Default: maintain current values
    next_state = state;
    next_bit_counter = bit_counter;
    next_break_counter = break_counter;
    next_rx_data_reg = rx_data_reg;
    next_break_detect_reg = break_detect_reg;
    
    case (state)
      IDLE: begin
        if (rx_in == 0) begin
          next_state = START;
          next_break_counter = 1; // Start counting zeros
        end
      end
      
      START: begin
        next_state = DATA;
        next_bit_counter = 0;
        next_break_counter = (rx_in == 0) ? break_counter + 1 : 0;
      end
      
      DATA: begin
        next_break_counter = (rx_in == 0) ? break_counter + 1 : 0;
        
        // Shift in data bit
        next_rx_data_reg = {rx_in, rx_data_reg[7:1]};
        
        if (bit_counter == 7) 
          next_state = STOP;
        else 
          next_bit_counter = bit_counter + 1;
        
        // Check for break condition during data reception
        if (break_counter >= BREAK_THRESHOLD) begin
          next_state = BREAK;
          next_break_detect_reg = 1;
        end
      end
      
      STOP: begin
        if (rx_in == 1) begin // Valid stop bit
          next_state = WAIT_READY;
        end else begin
          next_break_counter = break_counter + 1;
          if (break_counter >= BREAK_THRESHOLD) begin
            next_state = BREAK;
            next_break_detect_reg = 1;
          end else 
            next_state = IDLE;
        end
      end
      
      BREAK: begin
        next_state = WAIT_READY;
      end
      
      WAIT_READY: begin
        // Wait for handshake completion
        if ((rx_valid && rx_ready) || (break_valid && break_ready)) begin
          next_state = IDLE;
          next_break_counter = 0;
          next_break_detect_reg = 0;
        end
        
        // Line returned to idle while waiting
        if (rx_in == 1 && state == BREAK) begin
          next_break_counter = 0;
        end
      end
      
      default: next_state = IDLE;
    endcase
  end
endmodule