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
  
  // LUT-based subtractor signals
  reg [7:0] lut_sub_a, lut_sub_b;
  wire [7:0] lut_sub_result;
  
  // LUT for 8-bit subtraction
  reg [7:0] sub_lut [0:15][0:15];
  integer i, j;
  
  // Initialize subtraction LUT
  initial begin
    for (i = 0; i < 16; i = i + 1) begin
      for (j = 0; j < 16; j = j + 1) begin
        sub_lut[i][j] = i - j;
      end
    end
  end
  
  // LUT-based subtractor implementation
  wire [3:0] lut_sub_a_high = lut_sub_a[7:4];
  wire [3:0] lut_sub_a_low = lut_sub_a[3:0];
  wire [3:0] lut_sub_b_high = lut_sub_b[7:4];
  wire [3:0] lut_sub_b_low = lut_sub_b[3:0];
  
  wire [7:0] partial_high = sub_lut[lut_sub_a_high][lut_sub_b_high];
  wire [7:0] partial_low = sub_lut[lut_sub_a_low][lut_sub_b_low];
  
  // Combine results
  assign lut_sub_result = {partial_high[3:0], partial_low[3:0]};
  
  // Clock gating
  assign uart_clk = main_clk & clock_gate;
  
  // Power management state machine with LUT-based subtractor
  always @(posedge main_clk or negedge reset_n) begin
    if (!reset_n) begin
      power_state <= SLEEP;
      clock_gate <= 0;
      idle_counter <= 0;
      lut_sub_a <= 0;
      lut_sub_b <= 0;
    end else begin
      if (power_state == SLEEP) begin
        if (enable || rx_in == 0 || tx_start) begin
          power_state <= AWAKE;
          clock_gate <= 1;
        end
      end else if (power_state == AWAKE) begin
        power_state <= ACTIVE;
        idle_counter <= 0;
      end else if (power_state == ACTIVE) begin
        if (rx_activity || tx_start || !tx_done) begin
          idle_counter <= 0;
          // Initialize subtractor operands
          lut_sub_a <= 8'hFF;
          lut_sub_b <= idle_counter;
        end else begin
          // Using LUT-based subtractor for counter decrement
          lut_sub_a <= 8'hFF;
          lut_sub_b <= idle_counter;
          idle_counter <= lut_sub_result;
          
          if (idle_counter == 8'hFF && !enable) begin
            power_state <= SLEEP;
            clock_gate <= 0;
          end
        end
      end
    end
  end
  
  // Edge detection for RX activity
  always @(posedge main_clk) begin
    rx_activity <= (rx_in == 0);
  end
  
  // TX state machine (runs on gated clock)
  reg [1:0] tx_state;
  reg [3:0] tx_bit_idx;
  reg [DATA_BITS-1:0] tx_shift_reg;
  
  always @(posedge uart_clk or negedge reset_n) begin
    if (!reset_n) begin
      tx_state <= 0;
      tx_bit_idx <= 0;
      tx_shift_reg <= 0;
      tx_out <= 1;
      tx_done <= 1;
    end else begin
      if (tx_state == 0) begin
        if (tx_start) begin 
          tx_state <= 1; 
          tx_shift_reg <= tx_data; 
          tx_done <= 0; 
        end
      end else if (tx_state == 1) begin
        tx_out <= 0; 
        tx_state <= 2; 
        tx_bit_idx <= 0;
      end else if (tx_state == 2) begin
        tx_out <= tx_shift_reg[0];
        tx_shift_reg <= {1'b0, tx_shift_reg[DATA_BITS-1:1]};
        if (tx_bit_idx == DATA_BITS-1) 
          tx_state <= 3;
        else 
          tx_bit_idx <= tx_bit_idx + 1;
      end else if (tx_state == 3) begin
        tx_out <= 1; 
        tx_state <= 0; 
        tx_done <= 1;
      end
    end
  end
  
  // RX state machine (runs on gated clock)
  reg [1:0] rx_state;
  reg [3:0] rx_bit_idx;
  reg [DATA_BITS-1:0] rx_shift_reg;
  
  always @(posedge uart_clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_state <= 0;
      rx_bit_idx <= 0;
      rx_shift_reg <= 0;
      rx_data <= 0;
      rx_valid <= 0;
    end else begin
      if (rx_state == 0) begin
        if (rx_in == 0) begin 
          rx_state <= 1; 
          rx_valid <= 0; 
        end
      end else if (rx_state == 1) begin
        rx_state <= 2; 
        rx_bit_idx <= 0;
      end else if (rx_state == 2) begin
        rx_shift_reg <= {rx_in, rx_shift_reg[DATA_BITS-1:1]};
        if (rx_bit_idx == DATA_BITS-1) 
          rx_state <= 3;
        else 
          rx_bit_idx <= rx_bit_idx + 1;
      end else if (rx_state == 3) begin
        if (rx_in == 1) begin
          rx_data <= rx_shift_reg;
          rx_valid <= 1;
        end
        rx_state <= 0;
      end
    end
  end
endmodule