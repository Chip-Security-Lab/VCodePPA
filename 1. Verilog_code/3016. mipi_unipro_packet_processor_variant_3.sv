//SystemVerilog
module mipi_unipro_packet_processor (
  input wire aclk,
  input wire aresetn,
  input wire [7:0] data_in,
  input wire sop,
  input wire eop,
  input wire valid_in,
  input wire tready, // AXI-Stream ready signal
  output wire [15:0] tdata, // AXI-Stream data output
  output wire tvalid, // AXI-Stream valid output
  output wire tlast, // AXI-Stream last output
  output wire error_crc
);

  // State definitions (One-cold encoding)
  localparam [3:0] STATE_IDLE            = 4'b1110; // Bit 0 is 0
  localparam [3:0] STATE_RECEIVING       = 4'b1101; // Bit 1 is 0
  localparam [3:0] STATE_PROCESS_TRIGGER = 4'b1011; // Bit 2 is 0
  localparam [3:0] STATE_OUTPUT_READY    = 4'b0111; // Bit 3 is 0

  // Internal registers for state and buffer
  reg [3:0] state; // Changed to 4 bits for one-cold encoding
  reg [7:0] packet_buffer [0:63]; // Assuming max packet size is 64 bytes
  reg [5:0] byte_count;

  // Registers for AXI-Stream outputs and error_crc
  reg [15:0] tdata_reg;
  reg tvalid_reg;
  reg tlast_reg;
  reg error_crc_reg;

  // --- Sequential Logic ---

  // Always Block 1: State Machine Logic
  // Handles state transitions based on inputs and current state.
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state <= STATE_IDLE;
    end else begin
      case (state)
        STATE_IDLE: begin
          if (valid_in && sop) begin
            state <= STATE_RECEIVING;
          end
          // If valid_in but no sop, stay in IDLE (ignore data)
        end

        STATE_RECEIVING: begin
          if (valid_in && eop) begin
            // Packet end detected, move to process trigger state
            state <= STATE_PROCESS_TRIGGER;
          end
          // If !valid_in, stay in RECEIVING (pause reception)
          // If valid_in && !eop, stay in RECEIVING (continue reception)
        end

        STATE_PROCESS_TRIGGER: begin
          // Processing logic happens in another block
          // After processing cycle, move to output ready state
          state <= STATE_OUTPUT_READY;
        end

        STATE_OUTPUT_READY: begin
          // Stay in this state until handshake completes
          if (tready) begin
            // Handshake complete, return to IDLE
            state <= STATE_IDLE;
          end
          // If !tready, stay in STATE_OUTPUT_READY
          // Input valid_in is ignored in this state
        end

        default: begin // Handle unexpected state - return to IDLE
            state <= STATE_IDLE;
        end
      endcase
    end
  end

  // Always Block 2: Input Data Buffering and Byte Count
  // Stores incoming data into the buffer and manages the byte count.
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      byte_count <= 6'd0;
      // packet_buffer doesn't need explicit reset if only written when needed
    end else begin
      case (state)
        STATE_IDLE: begin
          // Reset byte count when starting a new packet sequence
          byte_count <= 6'd0;
        end
        STATE_RECEIVING: begin
          if (valid_in) begin
            // Store data if buffer is not full
            if (byte_count < 6'd64) begin
                packet_buffer[byte_count] <= data_in;
                byte_count <= byte_count + 1'b1;
            end else begin
                // Buffer overflow - original code didn't handle error,
                // just stops counting/storing. Keep that behavior.
                // Could add an error flag here if needed.
            end
          end
        end
        STATE_PROCESS_TRIGGER: begin
          // byte_count holds the final count from reception
        end
        STATE_OUTPUT_READY: begin
           // byte_count holds the final count from reception
        end
        default: begin
          byte_count <= 6'd0; // Reset on unexpected state
        end
      endcase
    end
  end

  // Always Block 3: Packet Processing and Error Calculation
  // Performs packet processing (e.g., extracting data) and calculates error_crc.
  // This is triggered when entering STATE_PROCESS_TRIGGER.
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      tdata_reg <= 16'd0;
      error_crc_reg <= 1'b0; // Reset error
    end else begin
      // Default: hold values
      reg [15:0] next_tdata = tdata_reg;
      reg next_error_crc = error_crc_reg;

      case (state)
        STATE_IDLE: begin
          // Reset output data and error when starting a new packet
          next_tdata = 16'd0;
          next_error_crc = 1'b0;
        end
        STATE_RECEIVING: begin
          // Hold values during reception
        end
        STATE_PROCESS_TRIGGER: begin
          // --- Packet Processing Logic ---
          // Example processing: take first two bytes as 16-bit data
          if (byte_count >= 2) begin // Need at least 2 bytes for 16-bit data
              next_tdata = {packet_buffer[1], packet_buffer[0]}; // Example processing
              next_error_crc = 1'b0; // Example error calculation (none)
          end else begin
               // Handle short packet error
               next_tdata = 16'd0; // Or some error indicator value
               next_error_crc = 1'b1; // Indicate error for short packet
          end
          // --- End of Processing Logic ---
        end
        STATE_OUTPUT_READY: begin
          // Hold values computed in STATE_PROCESS_TRIGGER
          // These values are outputted via the assign statements
          // If handshake completes, values are held until next transition to IDLE
        end
        default: begin
          next_tdata = 16'd0;
          next_error_crc = 1'b1; // Indicate error for unexpected state
        end
      endcase
      tdata_reg <= next_tdata;
      error_crc_reg <= next_error_crc;
    end
  end

  // Always Block 4: Output Handshake Control
  // Manages the tvalid and tlast signals based on state and tready.
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      tvalid_reg <= 1'b0;
      tlast_reg <= 1'b0;
    end else begin
      // Default: hold values unless state or tready dictates change
      reg next_tvalid = tvalid_reg;
      reg next_tlast = tlast_reg;

      case (state)
        STATE_IDLE: begin
          // Ensure outputs are low
          next_tvalid = 1'b0;
          next_tlast = 1'b0;
        end
        STATE_RECEIVING: begin
          // Outputs remain low during reception
          next_tvalid = 1'b0;
          next_tlast = 1'b0;
        end
        STATE_PROCESS_TRIGGER: begin
          // Outputs remain low during processing (data not yet ready on bus)
          next_tvalid = 1'b0; // Will be asserted in the next state
          next_tlast = 1'b0; // Will be asserted in the next state
        end
        STATE_OUTPUT_READY: begin
          // Assert outputs, hold until handshake complete
          next_tvalid = 1'b1;
          next_tlast = 1'b1; // Assuming single AXI word output per packet
          if (tready) begin
            // Deassert outputs after handshake, transition to IDLE handled by State Machine block
            next_tvalid = 1'b0;
            next_tlast = 1'b0;
          end
        end
        default: begin
          // Reset outputs on unexpected state
          next_tvalid = 1'b0;
          next_tlast = 1'b0;
        end
      endcase
      tvalid_reg <= next_tvalid;
      tlast_reg <= next_tlast;
    end
  end

  // Assign outputs from registers
  assign tdata = tdata_reg;
  assign tvalid = tvalid_reg;
  assign tlast = tlast_reg;
  assign error_crc = error_crc_reg; // error_crc is registered and held with data

endmodule