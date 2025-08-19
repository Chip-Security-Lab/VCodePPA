//SystemVerilog
module mipi_unipro_packet_processor (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire sop, eop, valid_in,
  output reg [15:0] tc_data_out, // Unused in original code
  output reg tc_valid_out,
  output reg error_crc
);

  // State register using one-hot encoding
  reg [2:0] state_onehot;
  reg [2:0] next_state_onehot; // Registered next state for synchronous update

  reg [15:0] crc; // Unused in original code
  reg [7:0] packet_buffer [0:63];
  reg [5:0] byte_count;

  // Define state encoding for clarity (matching one-hot bits)
  localparam [2:0] STATE_IDLE      = 3'b001; // Corresponds to original index 0
  localparam [2:0] STATE_RECEIVING = 3'b010; // Corresponds to original index 1
  localparam [2:0] STATE_DONE      = 3'b100; // Corresponds to original index 2

  //------------------------------------------------------------------------
  // State Logic
  // Registers the next state calculated by the combinational logic
  //------------------------------------------------------------------------
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_onehot <= STATE_IDLE;
    end else begin
      state_onehot <= next_state_onehot;
    end
  end

  //------------------------------------------------------------------------
  // Next State Calculation Logic
  // Determines the next state based on current state and inputs (combinational)
  // State transitions only occur when valid_in is high, matching original logic
  //------------------------------------------------------------------------
  always @(*) begin
      // Default: stay in current state if no valid transition condition is met or valid_in is low
      next_state_onehot = state_onehot;

      if (valid_in) begin // State transitions logic is gated by valid_in
          case (state_onehot)
            STATE_IDLE: begin
              if (sop) begin
                next_state_onehot = STATE_RECEIVING;
              end
            end
            STATE_RECEIVING: begin
              if (eop) begin
                next_state_onehot = STATE_DONE;
              end
            end
            STATE_DONE: begin
              next_state_onehot = STATE_IDLE;
            end
            default: begin // Handle invalid one-hot states
              next_state_onehot = STATE_IDLE;
            end
          endcase
      end
  end

  //------------------------------------------------------------------------
  // Data Path and Count Logic
  // Handles buffering data into packet_buffer and updating byte_count
  // Updates only occur when valid_in is high, matching original logic
  //------------------------------------------------------------------------
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      byte_count <= 6'd0;
      // packet_buffer does not need explicit reset based on original code
    end else if (valid_in) begin // Data path updates gated by valid_in
      case (state_onehot)
        STATE_IDLE: begin
          if (sop) begin
            // Reset count when starting a new packet (transitioning to RECEIVING)
            byte_count <= 6'd0;
          end
        end
        STATE_RECEIVING: begin
          // Buffer data and increment count
          packet_buffer[byte_count] <= data_in;
          byte_count <= byte_count + 1'b1;
        end
        // STATE_DONE and default: byte_count and packet_buffer hold value
      endcase
    end
    // If !valid_in, byte_count and packet_buffer hold value implicitly
  end

  //------------------------------------------------------------------------
  // Output Logic
  // Handles assertion/de-assertion of tc_valid_out
  // Updates only occur when valid_in is high, matching original logic
  //------------------------------------------------------------------------
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      tc_valid_out <= 1'b0;
    end else if (valid_in) begin // Output updates gated by valid_in
      case (state_onehot)
        STATE_RECEIVING: begin
          if (eop) begin
            // Assert valid when transitioning to DONE
            tc_valid_out <= 1'b1;
          end
        end
        STATE_DONE: begin
          // De-assert valid when transitioning to IDLE
          tc_valid_out <= 1'b0;
        end
        // STATE_IDLE and default: tc_valid_out holds value
      endcase
    end
    // If !valid_in, tc_valid_out holds value implicitly
  end

  //------------------------------------------------------------------------
  // Error Logic
  // Handles error_crc (only reset in original code)
  //------------------------------------------------------------------------
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      error_crc <= 1'b0;
    end
    // In original code, error_crc is never set, only reset.
    // No assignment is needed here when valid_in is high.
  end

  //------------------------------------------------------------------------
  // Unused Signals
  // tc_data_out and crc are unused in the original code
  //------------------------------------------------------------------------
  // tc_data_out is never assigned.
  // crc is never used.

endmodule