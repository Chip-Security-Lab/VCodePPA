//SystemVerilog
module uart_oversampling #(parameter CLK_FREQ = 48_000_000, BAUD = 115200) (
  input wire clk, rst_n,
  input wire rx,
  output reg [7:0] rx_data,
  output reg rx_valid
);
  // Calculate oversampling rate (16x standard)
  localparam OSR = 16;
  localparam CLKS_PER_BIT = CLK_FREQ / (BAUD * OSR);
  
  // State machine definitions
  localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  reg [1:0] state, next_state;
  
  // Counters
  reg [$clog2(CLKS_PER_BIT)-1:0] clk_counter;
  reg [3:0] os_counter; // Oversampling counter
  reg [2:0] bit_counter;
  
  // Sample registers
  reg [7:0] shift_reg;
  reg [OSR-1:0] sample_window;
  
  // Optimized comparison signals
  wire clk_cycle_end = (clk_counter == CLKS_PER_BIT-1);
  wire start_bit_middle = (os_counter == OSR/2);
  wire sample_complete = (os_counter == OSR-1);
  wire byte_complete = (bit_counter == 7);
  wire stop_bit_middle = start_bit_middle; // Reuse comparison
  
  // Next state logic
  always @(*) begin
    next_state = state; // Default: stay in current state
    
    case (state)
      IDLE: 
        if (rx == 1'b0) next_state = START;
      
      START: 
        if (clk_cycle_end && start_bit_middle) next_state = DATA;
      
      DATA: 
        if (clk_cycle_end && sample_complete && byte_complete) next_state = STOP;
      
      STOP: 
        if (clk_cycle_end && stop_bit_middle) next_state = IDLE;
    endcase
  end
  
  // Majority voting function
  function bit_value(input [OSR-1:0] samples);
    integer i, count;
    begin
      count = 0;
      for (i = 0; i < OSR; i = i + 1)
        if (samples[i]) count = count + 1;
      
      bit_value = (count > (OSR/2));
    end
  endfunction

  // Main sequential logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      clk_counter <= 0;
      os_counter <= 0;
      bit_counter <= 0;
      shift_reg <= 0;
      rx_data <= 0;
      rx_valid <= 0;
      sample_window <= 0;
    end else begin
      // Default assignments
      rx_valid <= 0;
      state <= next_state;
      
      // Counter management
      if (clk_cycle_end) begin
        clk_counter <= 0;
        
        case (state)
          IDLE: begin
            // Reset counters when entering START
            if (next_state == START) begin
              os_counter <= 0;
            end
          end
          
          START: begin
            if (start_bit_middle && next_state == DATA) begin
              bit_counter <= 0;
              os_counter <= 0;
            end else begin
              os_counter <= os_counter + 1;
            end
          end
          
          DATA: begin
            // Update sample window
            sample_window <= {sample_window[OSR-2:0], rx};
            
            if (sample_complete) begin
              // Use majority voting to determine bit value
              shift_reg[bit_counter] <= bit_value(sample_window);
              
              if (byte_complete) begin
                os_counter <= 0;
              end else begin
                bit_counter <= bit_counter + 1;
                os_counter <= 0;
              end
            end else begin
              os_counter <= os_counter + 1;
            end
          end
          
          STOP: begin
            if (stop_bit_middle) begin
              rx_data <= shift_reg;
              rx_valid <= 1;
            end else begin
              os_counter <= os_counter + 1;
            end
          end
        endcase
      end else begin
        clk_counter <= clk_counter + 1;
      end
    end
  end
endmodule