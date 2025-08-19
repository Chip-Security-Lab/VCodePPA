//SystemVerilog
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
  
  // Manchester Carry Chain signals for break_counter increment
  wire [3:0] p, g; // Propagate and generate signals
  wire [4:0] c; // Carry signals (including initial carry-in)
  
  // Generate propagate and generate signals for Manchester adder
  assign p = 4'b1111; // For increment operation, propagate is always 1
  assign g = break_counter; // For increment, generate equals the original value
  
  // Manchester carry chain calculation
  assign c[0] = 1'b1; // Carry-in for increment operation is 1
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
  
  // Wire for break_counter increment result
  wire [3:0] break_counter_plus_one;
  assign break_counter_plus_one = p ^ c[3:0]; // XOR of propagate and carry gives sum
  
  // Manchester Carry Chain signals for bit_counter increment
  wire [2:0] bit_p, bit_g; // Propagate and generate signals for bit_counter
  wire [3:0] bit_c; // Carry signals for bit_counter
  
  // Generate propagate and generate signals for bit_counter Manchester adder
  assign bit_p = 3'b111; // For increment operation, propagate is always 1
  assign bit_g = bit_counter; // For increment, generate equals the original value
  
  // Manchester carry chain calculation for bit_counter
  assign bit_c[0] = 1'b1; // Carry-in for increment operation is 1
  assign bit_c[1] = bit_g[0] | (bit_p[0] & bit_c[0]);
  assign bit_c[2] = bit_g[1] | (bit_p[1] & bit_g[0]) | (bit_p[1] & bit_p[0] & bit_c[0]);
  assign bit_c[3] = bit_g[2] | (bit_p[2] & bit_g[1]) | (bit_p[2] & bit_p[1] & bit_g[0]) | (bit_p[2] & bit_p[1] & bit_p[0] & bit_c[0]);
  
  // Wire for bit_counter increment result
  wire [2:0] bit_counter_plus_one;
  assign bit_counter_plus_one = bit_p ^ bit_c[2:0]; // XOR of propagate and carry gives sum
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      bit_counter <= 0;
      break_counter <= 0;
      rx_data <= 0;
      rx_valid <= 0;
      break_detect <= 0;
    end else begin
      if (state == IDLE) begin
        rx_valid <= 0;
        break_detect <= 0;
        if (rx_in == 0) begin
          state <= START;
          break_counter <= 1; // Start counting zeros
        end
      end else if (state == START) begin
        state <= DATA;
        bit_counter <= 0;
        if (rx_in == 0) break_counter <= break_counter_plus_one;
        else break_counter <= 0;
      end else if (state == DATA) begin
        if (rx_in == 0) break_counter <= break_counter_plus_one;
        else break_counter <= 0;
        
        // Shift in data bit
        rx_data <= {rx_in, rx_data[7:1]};
        
        if (bit_counter == 7) state <= STOP;
        else bit_counter <= bit_counter_plus_one;
        
        // Check for break condition during data reception
        if (break_counter >= BREAK_THRESHOLD) begin
          state <= BREAK;
          break_detect <= 1;
        end
      end else if (state == STOP) begin
        if (rx_in == 1) begin // Valid stop bit
          rx_valid <= 1;
          state <= IDLE;
          break_counter <= 0;
        end else begin
          break_counter <= break_counter_plus_one;
          if (break_counter >= BREAK_THRESHOLD) begin
            state <= BREAK;
            break_detect <= 1;
          end else state <= IDLE;
        end
      end else if (state == BREAK) begin
        // Stay in BREAK state until we see a 1 (indicating line idle)
        if (rx_in == 1) begin
          state <= IDLE;
          break_counter <= 0;
        end
      end
    end
  end
endmodule