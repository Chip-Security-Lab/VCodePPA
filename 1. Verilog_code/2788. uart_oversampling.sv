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
  reg [1:0] state;
  
  // Counters
  reg [$clog2(CLKS_PER_BIT*OSR)-1:0] clk_counter;
  reg [3:0] os_counter; // Oversampling counter
  reg [2:0] bit_counter;
  
  // Sample registers
  reg [7:0] shift_reg;
  reg [OSR-1:0] sample_window;
  
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
      case (state)
        IDLE: begin
          rx_valid <= 0;
          if (rx == 0) begin // Start bit detected
            state <= START;
            clk_counter <= 0;
            os_counter <= 0;
          end
        end
        START: begin
          // Sample through the start bit to find center
          if (clk_counter == CLKS_PER_BIT-1) begin
            clk_counter <= 0;
            if (os_counter == OSR/2) begin // Middle of start bit
              state <= DATA;
              bit_counter <= 0;
            end else os_counter <= os_counter + 1;
          end else clk_counter <= clk_counter + 1;
        end
        DATA: begin
          if (clk_counter == CLKS_PER_BIT-1) begin
            clk_counter <= 0;
            
            // Fill sample window
            sample_window <= {sample_window[OSR-2:0], rx};
            
            if (os_counter == OSR-1) begin
              // Determine bit value by majority voting
              shift_reg[bit_counter] <= (^sample_window) && (sample_window != 0);
              
              if (bit_counter == 7) begin
                state <= STOP;
                os_counter <= 0;
              end else bit_counter <= bit_counter + 1;
            end else os_counter <= os_counter + 1;
          end else clk_counter <= clk_counter + 1;
        end
        STOP: begin
          if (clk_counter == CLKS_PER_BIT-1) begin
            clk_counter <= 0;
            if (os_counter == OSR/2) begin // Middle of stop bit
              state <= IDLE;
              rx_data <= shift_reg;
              rx_valid <= 1;
            end else os_counter <= os_counter + 1;
          end else clk_counter <= clk_counter + 1;
        end
      endcase
    end
  end
endmodule