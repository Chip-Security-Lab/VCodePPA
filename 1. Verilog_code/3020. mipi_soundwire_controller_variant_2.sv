//SystemVerilog
//----------------------------------------------------------------------------
// Top-level module: MIPI Soundwire Controller
// Orchestrates data transmission based on Soundwire protocol principles.
// Decomposed into clock generation, control logic, and data path submodules.
//----------------------------------------------------------------------------
module mipi_soundwire_controller (
  input wire clk,         // System clock
  input wire reset_n,     // Asynchronous active-low reset
  input wire [15:0] audio_in, // 16-bit audio data input
  input wire audio_valid, // Indicates valid audio data is available
  output reg sdout,       // Serial data output
  output reg sclk,        // Serial clock output (generated internally)
  output reg ws,          // Word sync output (toggles per word)
  output reg ready        // Indicates controller is ready to accept new data
);

  // Internal wires to connect submodules
  wire [7:0] w_bit_count; // Current bit position within a word

  // Instantiate Clock Generator submodule
  // Generates the sclk signal.
  sclk_generator u_sclk_gen (
    .clk(clk),
    .reset_n(reset_n),
    .sclk_out(sclk) // Connects directly to top-level output reg
  );

  // Instantiate Control Logic submodule
  // Manages the bit counter, ready signal, and word sync.
  control_state_machine u_ctrl_sm (
    .clk(clk),
    .reset_n(reset_n),
    .sclk_in(sclk),         // Uses the generated sclk
    .audio_valid(audio_valid),
    .bit_count_out(w_bit_count), // Output bit count
    .ready_out(ready),      // Connects directly to top-level output reg
    .ws_out(ws)             // Connects directly to top-level output reg
  );

  // Instantiate Data Path submodule
  // Handles shift register loading, shifting, and serial data output.
  data_shifter u_data_shifter (
    .clk(clk),
    .reset_n(reset_n),
    .sclk_in(sclk),         // Uses the generated sclk
    .audio_in(audio_in),
    .bit_count_in(w_bit_count), // Uses bit count from control logic
    .ready_in(ready),       // Uses ready signal from control logic
    .sdout_out(sdout)       // Connects directly to top-level output reg
  );

endmodule

//----------------------------------------------------------------------------
// Submodule: sclk_generator
// Generates the sclk signal by toggling on each clk edge.
// Handles the asynchronous reset for sclk.
//----------------------------------------------------------------------------
module sclk_generator (
  input wire clk,       // System clock
  input wire reset_n,   // Asynchronous active-low reset
  output reg sclk_out   // Generated serial clock output
);

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sclk_out <= 1'b0;
    end else begin
      sclk_out <= ~sclk_out;
    end
  end

endmodule

//----------------------------------------------------------------------------
// Submodule: control_state_machine
// Manages the bit counter, ready signal, word sync, and frame counter.
// Logic updates are synchronized to clk, and actions are based on the
// state of sclk before the clk edge.
//----------------------------------------------------------------------------
module control_state_machine (
  input wire clk,         // System clock
  input wire reset_n,     // Asynchronous active-low reset
  input wire sclk_in,     // Input serial clock
  input wire audio_valid, // Indicates valid audio data is available
  output reg [7:0] bit_count_out, // Current bit position within a word
  output reg ready_out,   // Indicates controller is ready to accept new data
  output reg ws_out       // Word sync output (toggles per word)
);

  reg [9:0] frame_count; // Unused in original logic, kept for equivalence

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      bit_count_out <= 8'd0;
      ready_out <= 1'b1;
      ws_out <= 1'b0;
      frame_count <= 10'd0; // Reset frame_count
    end else begin
      // Logic for sclk transition 0->1 (sclk_in was 0 before posedge clk)
      if (sclk_in == 1'b0) begin
        case (bit_count_out)
          8'd0: begin // At the start of a word/frame
            if (audio_valid && ready_out) begin
              ready_out <= 1'b0; // Not ready to load new data until this word is sent
            end
          end
          8'd15: begin // At the end of a word/frame
            ws_out <= ~ws_out; // Toggle word sync
            ready_out <= 1'b1; // Ready to load new data for the next word
            // frame_count increment could be added here if used
            // frame_count <= frame_count + 1;
          end
          default: begin
            // No specific state update on rising edge for other bit_count values
          end
        endcase
      end else begin // sclk_in == 1'b1, Logic for sclk transition 1->0
        // Update bit counter
        if (bit_count_out == 8'd15) begin
          bit_count_out <= 8'd0; // Reset counter at the end of the word
        end else begin
          bit_count_out <= bit_count_out + 1'b1; // Increment counter
        end
      end
    end
  end

endmodule

//----------------------------------------------------------------------------
// Submodule: data_shifter
// Handles the shift register loading, shifting, and serial data output (sdout).
// Data loading occurs during the sclk 0->1 transition phase based on control
// signals. Data shifting and output occur during the sclk 1->0 transition phase.
//----------------------------------------------------------------------------
module data_shifter (
  input wire clk,         // System clock
  input wire reset_n,     // Asynchronous active-low reset
  input wire sclk_in,     // Input serial clock
  input wire [15:0] audio_in, // 16-bit audio data input
  input wire [7:0] bit_count_in, // Current bit position from control logic
  input wire ready_in,    // Ready signal from control logic
  output reg sdout_out    // Serial data output
);

  reg [15:0] shift_reg; // Shift register for serial transmission

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      shift_reg <= 16'b0; // Reset shift_reg
      sdout_out <= 1'b0; // Reset sdout
    end else begin
      // Logic for sclk transition 0->1 (sclk_in was 0 before posedge clk)
      if (sclk_in == 1'b0) begin
        // Load data at the start of a word/frame if valid and ready
        if (bit_count_in == 8'd0 && ready_in) begin // audio_valid check is handled by ready_in from control_state_machine
          shift_reg <= audio_in; // Load data into shift register
        end
        // sdout does not update in this phase
      end else begin // sclk_in == 1'b1, Logic for sclk transition 1->0
        // Shift out data and update shift register
        sdout_out <= shift_reg[15];
        shift_reg <= {shift_reg[14:0], 1'b0};
        // shift_reg is not loaded in this phase
      end
    end
  end

endmodule