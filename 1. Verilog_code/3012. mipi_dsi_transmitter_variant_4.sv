//SystemVerilog
module mipi_dsi_transmitter #(
  parameter DATA_LANES = 2,
  parameter BYTE_WIDTH = 8
)(
  input wire clk_hs, rst_n,
  input wire [BYTE_WIDTH-1:0] pixel_data,
  input wire start_tx, is_command,
  output reg [DATA_LANES-1:0] hs_data_out,
  output reg hs_clk_out,
  output reg tx_done, busy
);
  localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;
  reg [1:0] state;
  reg [5:0] counter;

  // Wires for borrow subtraction logic (counter - 1)
  wire [5:0] next_counter;
  wire [5:0] borrow_in_chain; // borrow_in[i] for bit i calculation
  wire [5:0] borrow_out_chain; // borrow_out[i] generated from bit i

  // Combinational logic for borrow subtraction
  // next_counter = counter - 1
  // B = 6'b000001

  // Bit 0: A[0] - B[0] - borrow_in[0] = counter[0] - 1 - 0
  assign borrow_in_chain[0] = 1'b0; // No borrow into LSB
  assign next_counter[0] = counter[0] ^ 1'b1 ^ borrow_in_chain[0]; // counter[0] ^ 1
  assign borrow_out_chain[0] = (~counter[0] & 1'b1) | (~counter[0] & borrow_in_chain[0]) | (1'b1 & borrow_in_chain[0]); // Simplified: ~counter[0]

  // Bits 1 to 5: A[i] - B[i] - borrow_in[i] = counter[i] - 0 - borrow_in[i]
  genvar i;
  generate
    for (i = 1; i < 6; i = i + 1) begin : borrow_sub_bits
      assign borrow_in_chain[i] = borrow_out_chain[i-1];
      assign next_counter[i] = counter[i] ^ 1'b0 ^ borrow_in_chain[i]; // Simplified: counter[i] ^ borrow_in_chain[i]
      assign borrow_out_chain[i] = (~counter[i] & 1'b0) | (~counter[i] & borrow_in_chain[i]) | (1'b0 & borrow_in_chain[i]); // Simplified: ~counter[i] & borrow_in_chain[i]
    end
  endgenerate

  always @(posedge clk_hs) begin
    if (!rst_n) begin
      state <= IDLE;
      hs_data_out <= {DATA_LANES{1'b0}}; // Original code resets this
      hs_clk_out <= 1'b0; // Assuming clock output has a reset state
      tx_done <= 1'b0;
      busy <= 1'b0;
      counter <= 6'b0; // Reset counter value
    end else begin
      tx_done <= 1'b0; // Clear tx_done unless set in EOP
      // hs_clk_out driving logic is not in the original snippet's always block
      // Leaving it undriven here as well, assuming it's driven combinatorially or elsewhere.

      case (state)
        IDLE: begin
          if (start_tx) begin
            state <= SYNC;
            busy <= 1'b1;
          end
        end
        SYNC: begin
          state <= DATA;
          counter <= 6'd32; // Initialize counter for decrementing (33 cycles: 32 down to 0)
        end
        DATA: begin
          if (counter == 6'd0) begin // Check for counter reaching 0
            state <= EOP;
          end else begin
            counter <= next_counter; // Load the decremented value from borrow logic
          end
        end
        EOP: begin
          tx_done <= 1'b1; // Pulse tx_done
          state <= IDLE;
          busy <= 1'b0;
        end
        default: begin // Should not happen in normal operation
          state <= IDLE;
          busy <= 1'b0;
        end
      endcase
    end
  end

  // hs_data_out and hs_clk_out are outputs, but their driving logic
  // is not fully specified in the original snippet beyond reset for hs_data_out.
  // Keeping them as outputs but not adding driving logic beyond the reset.
  // hs_clk_out is not driven in the original always block.

endmodule