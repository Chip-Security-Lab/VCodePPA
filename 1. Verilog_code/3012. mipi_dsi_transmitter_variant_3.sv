//SystemVerilog
module mipi_dsi_transmitter #(
  parameter DATA_LANES = 2,
  parameter BYTE_WIDTH = 8
)(
  input wire clk_hs, rst_n,
  input wire [BYTE_WIDTH-1:0] pixel_data, // Unused in original logic
  input wire start_tx, is_command,       // is_command unused in original logic
  output reg [DATA_LANES-1:0] hs_data_out,
  output reg hs_clk_out,                 // Unassigned in original logic
  output reg tx_done, busy
);

  localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;

  // State register
  reg [1:0] state;

  // Counter register
  // Used for decrementing from 32 down to 0
  reg [5:0] counter;

  localparam DATA_CYCLE_COUNT = 6'd32; // Counter starts at 32, counts down to 0

  //----------------------------------------------------------------------------
  // State Machine Logic
  // Updates the current state based on inputs and current state.
  //----------------------------------------------------------------------------
  always @(posedge clk_hs or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE:
          if (start_tx) begin
            state <= SYNC;
          end
        SYNC:
          state <= DATA;
        DATA:
          // Transition to EOP when counter reaches 0 (after decrementing from 32)
          if (counter == 6'd0) begin
            state <= EOP;
          end
        EOP:
          state <= IDLE;
        default: // Should not happen in normal operation
          state <= IDLE;
      endcase
    end
  end

  //----------------------------------------------------------------------------
  // Counter Logic
  // Updates the counter based on the current state.
  // Initializes in SYNC state, decrements in DATA state.
  // Uses subtraction (borrow algorithm) for decrement.
  //----------------------------------------------------------------------------
  always @(posedge clk_hs or negedge rst_n) begin
    if (!rst_n) begin
      // Counter is not explicitly reset on global reset in original code.
      // Maintaining original behavior where reset happens upon entering SYNC.
    end else begin
      case (state)
        SYNC:
          // Initialize counter to 32 when transitioning from SYNC to DATA
          counter <= DATA_CYCLE_COUNT;
        DATA:
          // Decrement counter while in DATA state using subtraction
          counter <= counter - 1'b1;
        default:
          // Hold counter value in IDLE and EOP states
          ; // No assignment means value is held
      endcase
    end
  end

  //----------------------------------------------------------------------------
  // Output Logic
  // Updates output signals based on state transitions and current state.
  // hs_data_out is only reset in the original code.
  // hs_clk_out is unassigned in the original code.
  //----------------------------------------------------------------------------
  always @(posedge clk_hs or negedge rst_n) begin
    if (!rst_n) begin
      hs_data_out <= {DATA_LANES{1'b0}};
      tx_done <= 1'b0;
      busy <= 1'b0;
      // hs_clk_out is not assigned in the original code
    end else begin
      // busy signal update
      // busy goes high when starting (transitioning from IDLE to SYNC)
      if (state == IDLE && start_tx) begin
        busy <= 1'b1;
      end
      // busy goes low when finishing (transitioning from EOP to IDLE)
      else if (state == EOP) begin
        busy <= 1'b0;
      end
      // busy holds its value otherwise

      // tx_done signal update
      // tx_done is high for one cycle when transitioning from EOP to IDLE
      if (state == EOP) begin
        tx_done <= 1'b1;
      end else begin
        tx_done <= 1'b0; // Clear tx_done otherwise
      end

      // hs_data_out is only reset in the original code, no other updates
      // hs_clk_out is not assigned in the original code
    end
  end

  // hs_clk_out remains unassigned as per original code
  // hs_data_out remains unchanged after reset as per original code

endmodule