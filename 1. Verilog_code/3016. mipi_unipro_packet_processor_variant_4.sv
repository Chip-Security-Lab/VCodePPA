//SystemVerilog
module mipi_unipro_packet_processor (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire sop, eop, valid_in,
  output reg [15:0] tc_data_out,
  output reg tc_valid_out,
  output reg error_crc
);

  // Use parameters for states for clarity
  localparam STATE_IDLE = 3'd0;
  localparam STATE_PACKET = 3'd1;
  localparam STATE_END = 3'd2;
  localparam STATE_DEFAULT = 3'd3; // Representing the default case

  reg [2:0] state;
  reg [15:0] crc; // Not assigned in original code, kept as is
  reg [7:0] packet_buffer [0:63]; // Not used beyond writing in original code, kept as is
  reg [5:0] byte_count;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= STATE_IDLE;
      byte_count <= 6'd0;
      error_crc <= 1'b0;
      tc_valid_out <= 1'b0;
    end else begin
      // State transitions and updates gated by valid_in, except for holding state/outputs
      if (valid_in) begin
        // Refactoring the case(state) comparison chain into if-else if
        if (state == STATE_IDLE) begin
          // Logic for STATE_IDLE (3'd0)
          if (sop) begin
            state <= STATE_PACKET;
            byte_count <= 6'd0; // Reset count on packet start
            tc_valid_out <= 1'b0; // Still building packet
          end
          // else state holds STATE_IDLE, byte_count holds, tc_valid_out holds 0
        end else if (state == STATE_PACKET) begin
          // Logic for STATE_PACKET (3'd1)
          // Original code wrote to buffer but didn't use it: packet_buffer[byte_count] <= data_in;
          byte_count <= byte_count + 1; // Increment count
          if (eop) begin
            state <= STATE_END;
            tc_valid_out <= 1'b1; // Packet complete, assert valid
          end
          // else state holds STATE_PACKET, tc_valid_out holds 0
        end else if (state == STATE_END) begin
          // Logic for STATE_END (3'd2)
          state <= STATE_IDLE; // Return to idle
          tc_valid_out <= 1'b0; // De-assert valid immediately
          // byte_count holds its value from state 1
        end else begin // Logic for default state (any state other than 0, 1, 2)
          state <= STATE_IDLE;
          byte_count <= 6'd0;
          tc_valid_out <= 1'b0;
          error_crc <= 1'b0; // Reset error on entering default and returning to idle
        end
      end
      // else (!valid_in): state, byte_count, error_crc, and tc_valid_out hold their values
      // due to the nature of synchronous assignments only happening within the if(valid_in) block.
    end
  end

  // Original code does not assign tc_data_out or crc, keeping them as is.
  // tc_data_out remains unassigned output reg.
  // crc remains unassigned reg.
  // error_crc is assigned only on reset and in the default state transition as per original code.

endmodule