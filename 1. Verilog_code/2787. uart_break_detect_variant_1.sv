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
  
  // Pipeline stages
  // Stage 1: State detection and input processing
  reg [2:0] state_s1, state_s2;
  reg rx_in_s1, rx_in_s2;
  reg [2:0] bit_counter_s1, bit_counter_s2;
  reg [3:0] break_counter_s1, break_counter_s2;
  reg [7:0] rx_data_s1, rx_data_s2;
  reg rx_valid_s1, rx_valid_s2;
  reg break_detect_s1, break_detect_s2;
  reg stage1_valid, stage2_valid;
  
  // UART parameters
  localparam BREAK_THRESHOLD = 10; // Number of bits to detect break
  
  // Carry look-ahead adder signals for break_counter
  wire [3:0] break_counter_plus_one;
  wire [3:0] g; // Generate signals
  wire [3:0] p; // Propagate signals
  wire [4:0] c; // Carry signals (including initial carry-in)
  
  // Generate and propagate signals for CLA
  assign g[0] = break_counter_s1[0] & 1'b1;
  assign g[1] = break_counter_s1[1] & 1'b0;
  assign g[2] = break_counter_s1[2] & 1'b0;
  assign g[3] = break_counter_s1[3] & 1'b0;
  
  assign p[0] = break_counter_s1[0] | 1'b1;
  assign p[1] = break_counter_s1[1] | 1'b0;
  assign p[2] = break_counter_s1[2] | 1'b0;
  assign p[3] = break_counter_s1[3] | 1'b0;
  
  // Carry look-ahead logic
  assign c[0] = 1'b0; // Initial carry-in
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign c[4] = g[3] | (p[3] & c[3]);
  
  // Sum computation
  assign break_counter_plus_one[0] = break_counter_s1[0] ^ 1'b1 ^ c[0];
  assign break_counter_plus_one[1] = break_counter_s1[1] ^ 1'b0 ^ c[1];
  assign break_counter_plus_one[2] = break_counter_s1[2] ^ 1'b0 ^ c[2];
  assign break_counter_plus_one[3] = break_counter_s1[3] ^ 1'b0 ^ c[3];
  
  // Stage 1 Pipeline: Input processing and state detection
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      state_s1 <= IDLE;
      bit_counter_s1 <= 0;
      break_counter_s1 <= 0;
      rx_data_s1 <= 0;
      rx_valid_s1 <= 0;
      break_detect_s1 <= 0;
      rx_in_s1 <= 1;
      stage1_valid <= 0;
    end else begin
      stage1_valid <= 1;
      rx_in_s1 <= rx_in;
      
      case (state_s1)
        IDLE: begin
          rx_valid_s1 <= 0;
          break_detect_s1 <= 0;
          if (rx_in == 0) begin
            state_s1 <= START;
            break_counter_s1 <= 1; // Start counting zeros
          end
        end
        START: begin
          state_s1 <= DATA;
          bit_counter_s1 <= 0;
          if (rx_in == 0) break_counter_s1 <= break_counter_plus_one;
          else break_counter_s1 <= 0;
        end
        DATA: begin
          if (rx_in == 0) break_counter_s1 <= break_counter_plus_one;
          else break_counter_s1 <= 0;
          
          // Update bit counter using CLA for bit_counter
          if (bit_counter_s1 == 7) state_s1 <= STOP;
          else bit_counter_s1 <= bit_counter_s1 + 1;
        end
        STOP: begin
          if (rx_in == 1) begin // Valid stop bit
            rx_valid_s1 <= 1;
            state_s1 <= IDLE;
            break_counter_s1 <= 0;
          end else begin
            break_counter_s1 <= break_counter_plus_one;
            if (break_counter_s1 >= BREAK_THRESHOLD) begin
              state_s1 <= BREAK;
              break_detect_s1 <= 1;
            end else state_s1 <= IDLE;
          end
        end
        BREAK: begin
          // Stay in BREAK state until we see a 1 (indicating line idle)
          if (rx_in == 1) begin
            state_s1 <= IDLE;
            break_counter_s1 <= 0;
          end
        end
      endcase
    end
  end
  
  // Bit counter CLA signals
  wire [2:0] bit_counter_plus_one;
  wire [2:0] bit_g; // Generate signals
  wire [2:0] bit_p; // Propagate signals
  wire [3:0] bit_c; // Carry signals (including initial carry-in)
  
  // Generate and propagate signals for bit counter CLA
  assign bit_g[0] = bit_counter_s2[0] & 1'b1;
  assign bit_g[1] = bit_counter_s2[1] & 1'b0;
  assign bit_g[2] = bit_counter_s2[2] & 1'b0;
  
  assign bit_p[0] = bit_counter_s2[0] | 1'b1;
  assign bit_p[1] = bit_counter_s2[1] | 1'b0;
  assign bit_p[2] = bit_counter_s2[2] | 1'b0;
  
  // Carry look-ahead logic for bit counter
  assign bit_c[0] = 1'b0; // Initial carry-in
  assign bit_c[1] = bit_g[0] | (bit_p[0] & bit_c[0]);
  assign bit_c[2] = bit_g[1] | (bit_p[1] & bit_c[1]);
  assign bit_c[3] = bit_g[2] | (bit_p[2] & bit_c[2]);
  
  // Sum computation for bit counter
  assign bit_counter_plus_one[0] = bit_counter_s2[0] ^ 1'b1 ^ bit_c[0];
  assign bit_counter_plus_one[1] = bit_counter_s2[1] ^ 1'b0 ^ bit_c[1];
  assign bit_counter_plus_one[2] = bit_counter_s2[2] ^ 1'b0 ^ bit_c[2];
  
  // Stage 2 Pipeline: Data processing and break detection
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      state_s2 <= IDLE;
      bit_counter_s2 <= 0;
      break_counter_s2 <= 0;
      rx_data_s2 <= 0;
      rx_valid_s2 <= 0;
      break_detect_s2 <= 0;
      stage2_valid <= 0;
    end else begin
      // Pipeline registers
      state_s2 <= state_s1;
      bit_counter_s2 <= bit_counter_s1;
      break_counter_s2 <= break_counter_s1;
      rx_valid_s2 <= rx_valid_s1;
      stage2_valid <= stage1_valid;
      
      // Process break detection in stage 2
      if (break_counter_s2 >= BREAK_THRESHOLD && state_s2 != BREAK) begin
        break_detect_s2 <= 1;
      end else begin
        break_detect_s2 <= break_detect_s1;
      end
      
      // Process data shifting in stage 2
      if (state_s2 == DATA) begin
        rx_data_s2 <= {rx_in_s1, rx_data_s2[7:1]};
      end else begin
        rx_data_s2 <= rx_data_s1;
      end
    end
  end
  
  // Output stage
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      rx_data <= 0;
      rx_valid <= 0;
      break_detect <= 0;
    end else if (stage2_valid) begin
      rx_data <= rx_data_s2;
      rx_valid <= rx_valid_s2;
      break_detect <= break_detect_s2;
    end
  end
endmodule