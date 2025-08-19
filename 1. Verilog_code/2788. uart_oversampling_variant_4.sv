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
  reg [1:0] state, state_stage1, state_stage2, state_stage3;
  
  // Counters
  reg [$clog2(CLKS_PER_BIT*OSR)-1:0] clk_counter;
  reg [3:0] os_counter; // Oversampling counter
  reg [2:0] bit_counter;
  
  // Sample registers
  reg [7:0] shift_reg;
  reg [OSR-1:0] sample_window;
  
  // Pipeline registers for breaking combinational paths - Stage 1
  reg clk_count_max_stage1;
  reg os_count_half_stage1;
  reg os_count_max_stage1;
  reg bit_count_max_stage1;
  reg [OSR-1:0] sample_window_stage1;
  
  // Pipeline registers - Stage 2
  reg clk_count_max_stage2;
  reg os_count_half_stage2;
  reg os_count_max_stage2;
  reg bit_count_max_stage2;
  reg [OSR-1:0] sample_window_stage2;
  reg [OSR/2-1:0] sample_sum_stage2;
  
  // Pipeline registers - Stage 3
  reg clk_count_max_stage3;
  reg os_count_half_stage3; 
  reg os_count_max_stage3;
  reg bit_count_max_stage3;
  reg majority_vote_stage3;
  reg rx_stage1, rx_stage2, rx_stage3;
  
  // Stage 1: Compute basic comparison results and pipeline input
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clk_count_max_stage1 <= 0;
      os_count_half_stage1 <= 0;
      os_count_max_stage1 <= 0;
      bit_count_max_stage1 <= 0;
      state_stage1 <= IDLE;
      sample_window_stage1 <= 0;
      rx_stage1 <= 1;
    end else begin
      // Stage 1: Pre-compute conditions
      clk_count_max_stage1 <= (clk_counter == CLKS_PER_BIT-1);
      os_count_half_stage1 <= (os_counter == OSR/2);
      os_count_max_stage1 <= (os_counter == OSR-1);
      bit_count_max_stage1 <= (bit_counter == 7);
      state_stage1 <= state;
      sample_window_stage1 <= sample_window;
      rx_stage1 <= rx;
    end
  end
  
  // Stage 2: First part of majority vote calculation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clk_count_max_stage2 <= 0;
      os_count_half_stage2 <= 0;
      os_count_max_stage2 <= 0;
      bit_count_max_stage2 <= 0;
      state_stage2 <= IDLE;
      sample_window_stage2 <= 0;
      sample_sum_stage2 <= 0;
      rx_stage2 <= 1;
    end else begin
      // Pass through computed conditions
      clk_count_max_stage2 <= clk_count_max_stage1;
      os_count_half_stage2 <= os_count_half_stage1;
      os_count_max_stage2 <= os_count_max_stage1;
      bit_count_max_stage2 <= bit_count_max_stage1;
      state_stage2 <= state_stage1;
      sample_window_stage2 <= sample_window_stage1;
      rx_stage2 <= rx_stage1;
      
      // Break down majority vote calculation - count ones in first half
      sample_sum_stage2 <= sample_window_stage1[0] + sample_window_stage1[1] + 
                          sample_window_stage1[2] + sample_window_stage1[3] +
                          sample_window_stage1[4] + sample_window_stage1[5] +
                          sample_window_stage1[6] + sample_window_stage1[7];
    end
  end
  
  // Stage 3: Complete majority vote calculation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clk_count_max_stage3 <= 0;
      os_count_half_stage3 <= 0;
      os_count_max_stage3 <= 0;
      bit_count_max_stage3 <= 0;
      state_stage3 <= IDLE;
      majority_vote_stage3 <= 0;
      rx_stage3 <= 1;
    end else begin
      // Pass through computed conditions
      clk_count_max_stage3 <= clk_count_max_stage2;
      os_count_half_stage3 <= os_count_half_stage2;
      os_count_max_stage3 <= os_count_max_stage2;
      bit_count_max_stage3 <= bit_count_max_stage2;
      state_stage3 <= state_stage2;
      rx_stage3 <= rx_stage2;
      
      // Complete majority vote calculation - count ones in second half and determine result
      majority_vote_stage3 <= (sample_sum_stage2 + 
                              sample_window_stage2[8] + sample_window_stage2[9] + 
                              sample_window_stage2[10] + sample_window_stage2[11] +
                              sample_window_stage2[12] + sample_window_stage2[13] +
                              sample_window_stage2[14] + sample_window_stage2[15]) > (OSR/2);
    end
  end
  
  // Final stage: Main state machine with deeply pipelined conditions
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
          if (rx_stage3 == 0) begin // Start bit detected
            state <= START;
            clk_counter <= 0;
            os_counter <= 0;
          end
        end
        START: begin
          // Sample through the start bit to find center
          if (clk_count_max_stage3) begin
            clk_counter <= 0;
            if (os_count_half_stage3) begin // Middle of start bit
              state <= DATA;
              bit_counter <= 0;
            end else os_counter <= os_counter + 1;
          end else clk_counter <= clk_counter + 1;
        end
        DATA: begin
          if (clk_count_max_stage3) begin
            clk_counter <= 0;
            
            // Fill sample window
            sample_window <= {sample_window[OSR-2:0], rx};
            
            if (os_count_max_stage3) begin
              // Use pipelined majority vote result from stage 3
              if (state_stage3 == DATA) begin
                shift_reg[bit_counter] <= majority_vote_stage3;
              
                if (bit_count_max_stage3) begin
                  state <= STOP;
                  os_counter <= 0;
                end else bit_counter <= bit_counter + 1;
              end
            end else os_counter <= os_counter + 1;
          end else clk_counter <= clk_counter + 1;
        end
        STOP: begin
          if (clk_count_max_stage3) begin
            clk_counter <= 0;
            if (os_count_half_stage3) begin // Middle of stop bit
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