//SystemVerilog
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
          // Flattened TX state machine
          if (tx_state[i] == 0 && tx_valid[i] && tx_ready[i]) begin
            // Idle -> Start bit transition
            tx_state[i] <= 1;
            tx_shift[i] <= tx_data[i];
            tx_ready[i] <= 0;
            tx_out[i] <= 1;
          end else if (tx_state[i] == 0) begin
            // Stay in idle
            tx_out[i] <= 1;
          end else if (tx_state[i] == 1) begin
            // Start bit
            tx_out[i] <= 0;
            tx_state[i] <= 2;
            tx_bit_count[i] <= 0;
          end else if (tx_state[i] == 2 && tx_bit_count[i] == 7) begin
            // Last data bit
            tx_out[i] <= tx_shift[i][0];
            tx_shift[i] <= {1'b0, tx_shift[i][7:1]};
            tx_state[i] <= 3;
          end else if (tx_state[i] == 2) begin
            // Data bits 0-6
            tx_out[i] <= tx_shift[i][0];
            tx_shift[i] <= {1'b0, tx_shift[i][7:1]};
            tx_bit_count[i] <= tx_bit_count[i] + 1;
          end else if (tx_state[i] == 3) begin
            // Stop bit
            tx_out[i] <= 1;
            tx_state[i] <= 0;
            tx_ready[i] <= 1;
          end
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
          if (rx_valid[i] && rx_ready[i]) begin
            rx_valid[i] <= 0;
          end
          
          // Flattened RX state machine
          if (rx_state[i] == 0 && rx_in[i] == 0) begin
            // Start bit detected
            rx_state[i] <= 1;
          end else if (rx_state[i] == 1) begin
            // Confirm start bit
            rx_state[i] <= 2;
            rx_bit_count[i] <= 0;
          end else if (rx_state[i] == 2 && rx_bit_count[i] == 7) begin
            // Last data bit
            rx_shift[i] <= {rx_in[i], rx_shift[i][7:1]};
            rx_state[i] <= 3;
          end else if (rx_state[i] == 2) begin
            // Data bits 0-6
            rx_shift[i] <= {rx_in[i], rx_shift[i][7:1]};
            rx_bit_count[i] <= rx_bit_count[i] + 1;
          end else if (rx_state[i] == 3 && rx_in[i] == 1 && !rx_valid[i]) begin
            // Valid stop bit received
            rx_state[i] <= 0;
            rx_data[i] <= rx_shift[i];
            rx_valid[i] <= 1;
          end else if (rx_state[i] == 3) begin
            // Invalid stop bit or already valid
            rx_state[i] <= 0;
          end
        end
      end
    end
  endgenerate
endmodule