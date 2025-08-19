module uart_multi_channel #(parameter CHANNELS = 4) (
  input wire clk, rst_n,
  input wire [CHANNELS-1:0] rx_in,
  output reg [CHANNELS-1:0] tx_out,
  input wire [7:0] tx_data [0:CHANNELS-1],
  input wire [CHANNELS-1:0] tx_valid,
  output reg [CHANNELS-1:0] tx_ready,
  output reg [7:0] rx_data [0:CHANNELS-1],
  output reg [CHANNELS-1:0] rx_valid,
  input wire [CHANNELS-1:0] rx_ready
);
  // Channel state tracking
  reg [1:0] tx_state [0:CHANNELS-1];
  reg [1:0] rx_state [0:CHANNELS-1];
  reg [2:0] tx_bit_count [0:CHANNELS-1];
  reg [2:0] rx_bit_count [0:CHANNELS-1];
  reg [7:0] tx_shift [0:CHANNELS-1];
  reg [7:0] rx_shift [0:CHANNELS-1];
  
  genvar i;
  generate
    for (i = 0; i < CHANNELS; i = i + 1) begin : channel
      // TX state machine per channel
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          tx_state[i] <= 0;
          tx_bit_count[i] <= 0;
          tx_shift[i] <= 0;
          tx_out[i] <= 1;
          tx_ready[i] <= 1;
        end else begin
          case (tx_state[i])
            0: begin // Idle
              tx_out[i] <= 1;
              if (tx_valid[i] && tx_ready[i]) begin
                tx_state[i] <= 1;
                tx_shift[i] <= tx_data[i];
                tx_ready[i] <= 0;
              end
            end
            1: begin // Start bit
              tx_out[i] <= 0;
              tx_state[i] <= 2;
              tx_bit_count[i] <= 0;
            end
            2: begin // Data bits
              tx_out[i] <= tx_shift[i][0];
              tx_shift[i] <= {1'b0, tx_shift[i][7:1]};
              if (tx_bit_count[i] == 7) tx_state[i] <= 3;
              else tx_bit_count[i] <= tx_bit_count[i] + 1;
            end
            3: begin // Stop bit
              tx_out[i] <= 1;
              tx_state[i] <= 0;
              tx_ready[i] <= 1;
            end
          endcase
        end
      end
      
      // RX state machine per channel
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          rx_state[i] <= 0;
          rx_bit_count[i] <= 0;
          rx_shift[i] <= 0;
          rx_data[i] <= 0;
          rx_valid[i] <= 0;
        end else begin
          // Clear valid flag when ready is asserted
          if (rx_valid[i] && rx_ready[i]) rx_valid[i] <= 0;
          
          case (rx_state[i])
            0: if (rx_in[i] == 0) rx_state[i] <= 1; // Start bit detected
            1: begin rx_state[i] <= 2; rx_bit_count[i] <= 0; end // Confirm start bit
            2: begin // Data bits
              rx_shift[i] <= {rx_in[i], rx_shift[i][7:1]};
              if (rx_bit_count[i] == 7) rx_state[i] <= 3;
              else rx_bit_count[i] <= rx_bit_count[i] + 1;
            end
            3: begin // Stop bit
              rx_state[i] <= 0;
              if (rx_in[i] == 1 && !rx_valid[i]) begin
                rx_data[i] <= rx_shift[i];
                rx_valid[i] <= 1;
              end
            end
          endcase
        end
      end
    end
  endgenerate
endmodule