//SystemVerilog
module mipi_dsi_transmitter #(
  parameter DATA_LANES = 2,
  parameter BYTE_WIDTH = 8
)(
  input wire clk_hs, rst_n,
  input wire [BYTE_WIDTH-1:0] pixel_data, // Input pixel_data is unused in original code
  input wire start_tx, is_command, // is_command is unused in original code
  output reg [DATA_LANES-1:0] hs_data_out,
  output reg hs_clk_out,
  output reg tx_done, busy
);
  localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;
  reg [1:0] state;
  reg [5:0] counter;

  // Pipeline register for start_tx input to reduce combinational path delay
  reg start_tx_pipe;

  // Pipelining stage for start_tx
  always @(posedge clk_hs) begin
    if (!rst_n) begin
      start_tx_pipe <= 1'b0;
    end else begin
      start_tx_pipe <= start_tx;
    end
  end

  // State machine and output logic
  always @(posedge clk_hs) begin
    if (!rst_n) begin
      state <= IDLE;
      hs_data_out <= {DATA_LANES{1'b0}};
      hs_clk_out <= 1'b0; // Initialize hs_clk_out
      tx_done <= 1'b0;
      busy <= 1'b0;
      counter <= 6'b0; // Initialize counter
    end else begin
      // Combinational logic for next state/values
      reg [1:0] next_state;
      reg [5:0] next_counter;
      reg next_tx_done;
      reg next_busy;
      // hs_data_out and hs_clk_out logic is missing in original,
      // and only updated on reset. Maintaining this behavior for functional equivalence
      // to the provided code snippet.

      next_state = state; // Default: stay in current state
      next_counter = counter; // Default: keep counter value
      next_tx_done = tx_done; // Default: keep value
      next_busy = busy; // Default: keep value

      case (state)
        IDLE: begin
          // Use the pipelined start_tx signal
          if (start_tx_pipe) begin
            next_state = SYNC;
            next_busy = 1'b1;
            next_tx_done = 1'b0; // Ensure tx_done is low when starting
          end
        end
        SYNC: begin
          next_state = DATA;
          next_counter = 6'b0; // Reset counter when entering DATA
        end
        DATA: begin
          if (counter == 6'd32) begin
            next_state = EOP;
          end else begin
            next_counter = counter + 1'b1;
          end
        end
        EOP: begin
          next_tx_done = 1'b1; // Signal done
          next_state = IDLE;
          next_busy = 1'b0;
        end
      endcase

      // Register updates
      state <= next_state;
      counter <= next_counter;
      tx_done <= next_tx_done;
      busy <= next_busy;
      // hs_data_out and hs_clk_out updates remain only on reset as per original code
    end
  end
endmodule