module uart_break_detect (
  input wire clock, reset_n,
  input wire rx_in,
  output reg [7:0] rx_data,
  output reg rx_valid,
  output reg break_detect
);
  // States
  localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, BREAK = 4;
  reg [2:0] state;
  
  // Counters
  reg [2:0] bit_counter;
  reg [3:0] break_counter; // Count consecutive zeros
  
  // UART parameters
  localparam BREAK_THRESHOLD = 10; // Number of bits to detect break
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      bit_counter <= 0;
      break_counter <= 0;
      rx_data <= 0;
      rx_valid <= 0;
      break_detect <= 0;
    end else begin
      case (state)
        IDLE: begin
          rx_valid <= 0;
          break_detect <= 0;
          if (rx_in == 0) begin
            state <= START;
            break_counter <= 1; // Start counting zeros
          end
        end
        START: begin
          state <= DATA;
          bit_counter <= 0;
          if (rx_in == 0) break_counter <= break_counter + 1;
          else break_counter <= 0;
        end
        DATA: begin
          if (rx_in == 0) break_counter <= break_counter + 1;
          else break_counter <= 0;
          
          // Shift in data bit
          rx_data <= {rx_in, rx_data[7:1]};
          
          if (bit_counter == 7) state <= STOP;
          else bit_counter <= bit_counter + 1;
          
          // Check for break condition during data reception
          if (break_counter >= BREAK_THRESHOLD) begin
            state <= BREAK;
            break_detect <= 1;
          end
        end
        STOP: begin
          if (rx_in == 1) begin // Valid stop bit
            rx_valid <= 1;
            state <= IDLE;
            break_counter <= 0;
          end else begin
            break_counter <= break_counter + 1;
            if (break_counter >= BREAK_THRESHOLD) begin
              state <= BREAK;
              break_detect <= 1;
            end else state <= IDLE;
          end
        end
        BREAK: begin
          // Stay in BREAK state until we see a 1 (indicating line idle)
          if (rx_in == 1) begin
            state <= IDLE;
            break_counter <= 0;
          end
        end
      endcase
    end
  end
endmodule