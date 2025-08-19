//SystemVerilog
module uart_break_detect (
  input wire clock, reset_n,
  input wire rx_in,
  
  // Enhanced Valid-Ready interface
  output wire [7:0] rx_data,
  output wire rx_valid,
  input wire rx_ready,
  
  output wire break_detect
);
  // States with optimized encoding
  localparam [2:0] IDLE = 3'b000, 
                  START = 3'b001, 
                  DATA = 3'b011, 
                  STOP = 3'b010, 
                  BREAK = 3'b110, 
                  WAIT_READY = 3'b100;
  
  reg [2:0] state, next_state;
  
  // Counters
  reg [2:0] bit_counter, next_bit_counter;
  reg [3:0] break_counter, next_break_counter;
  
  // UART parameters
  localparam BREAK_THRESHOLD = 10;
  
  // Internal signals
  reg [7:0] rx_data_buffer, next_rx_data_buffer;
  reg [7:0] rx_data_reg;
  reg rx_valid_reg, break_detect_reg;
  
  // Output assignments
  assign rx_data = rx_data_reg;
  assign rx_valid = rx_valid_reg;
  assign break_detect = break_detect_reg;
  
  // Next state and output logic
  always @(*) begin
    // Default: maintain current values
    next_state = state;
    next_bit_counter = bit_counter;
    next_break_counter = break_counter;
    next_rx_data_buffer = rx_data_buffer;
    
    case (state)
      IDLE: begin
        if (rx_in == 0) begin
          next_state = START;
          next_break_counter = 1;
        end
      end
      
      START: begin
        next_state = DATA;
        next_bit_counter = 0;
        next_break_counter = (rx_in == 0) ? break_counter + 1 : 0;
      end
      
      DATA: begin
        next_break_counter = (rx_in == 0) ? break_counter + 1 : 0;
        next_rx_data_buffer = {rx_in, rx_data_buffer[7:1]};
        
        if (bit_counter == 7)
          next_state = STOP;
        else
          next_bit_counter = bit_counter + 1;
          
        if (break_counter >= BREAK_THRESHOLD)
          next_state = BREAK;
      end
      
      STOP: begin
        if (rx_in == 1) begin
          next_state = WAIT_READY;
          next_break_counter = 0;
        end else begin
          next_break_counter = break_counter + 1;
          if (break_counter >= BREAK_THRESHOLD)
            next_state = BREAK;
          else
            next_state = IDLE;
        end
      end
      
      WAIT_READY: begin
        if (rx_ready)
          next_state = IDLE;
      end
      
      BREAK: begin
        if (rx_in == 1) begin
          next_state = IDLE;
          next_break_counter = 0;
        end
      end
      
      default: next_state = IDLE;
    endcase
  end
  
  // Sequential logic
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      bit_counter <= 0;
      break_counter <= 0;
      rx_data_buffer <= 0;
      rx_data_reg <= 0;
      rx_valid_reg <= 0;
      break_detect_reg <= 0;
    end else begin
      state <= next_state;
      bit_counter <= next_bit_counter;
      break_counter <= next_break_counter;
      rx_data_buffer <= next_rx_data_buffer;
      
      // Output registers
      case (state)
        STOP: begin
          if (rx_in == 1) begin
            rx_data_reg <= rx_data_buffer;
            rx_valid_reg <= 1;
          end
        end
        
        WAIT_READY: begin
          if (rx_ready)
            rx_valid_reg <= 0;
        end
        
        BREAK: begin
          break_detect_reg <= 1;
        end
        
        IDLE: begin
          rx_valid_reg <= 0;
          break_detect_reg <= 0;
        end
      endcase
    end
  end
endmodule