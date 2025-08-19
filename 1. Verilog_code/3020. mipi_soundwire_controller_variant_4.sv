//SystemVerilog
// Top level module: mipi_soundwire_controller
// This module instantiates and connects the sub-modules
// to implement the overall SoundWire controller functionality.
module mipi_soundwire_controller (
  input wire clk,       // System clock
  input wire reset_n,   // Active-low reset
  input wire [15:0] audio_in, // 16-bit audio data input
  input wire audio_valid, // Indicates audio_in is valid
  output wire sdout,    // Serial data output
  output wire sclk,     // Generated SCLK output
  output wire ws,       // Word Sync output
  output wire ready     // Indicates if the controller is ready for new data input
);

  // Internal wires for connecting submodules
  wire w_sclk;      // Connects sclk_gen to frame_controller and data_path
  wire w_load_en;   // Connects frame_controller to data_path
  wire w_ws;        // Connects frame_controller to top output
  wire w_ready;     // Connects frame_controller to top output
  wire w_sdout;     // Connects data_path to top output

  // Instantiate sclk generator module
  sclk_gen sclk_gen_inst (
    .clk (clk),
    .reset_n (reset_n),
    .sclk (w_sclk)
  );

  // Instantiate frame controller module
  frame_controller frame_controller_inst (
    .sclk (w_sclk),
    .reset_n (reset_n),
    .audio_valid (audio_valid),
    .load_en (w_load_en),
    .ws (w_ws),
    .ready (w_ready)
  );

  // Instantiate data path module
  data_path data_path_inst (
    .sclk (w_sclk),
    .reset_n (reset_n),
    .data_in (audio_in),
    .load_en (w_load_en),
    .sdout (w_sdout)
  );

  // Assign submodule outputs to top-level outputs
  assign sclk = w_sclk;
  assign ws = w_ws;
  assign ready = w_ready;
  assign sdout = w_sdout;

endmodule

// sclk_gen module
// Generates the SCLK signal by toggling on the input CLK edges.
module sclk_gen (
  input wire clk,       // Input system clock
  input wire reset_n,   // Active-low reset
  output reg sclk       // Generated SCLK signal
);
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sclk <= 1'b0;
    end else begin
      sclk <= ~sclk;
    end
  end
endmodule

// frame_controller module
// Manages the frame timing, bit count, word sync, and ready signals.
// Generates the load enable signal for the data path.
module frame_controller (
  input wire sclk,       // Generated SCLK signal
  input wire reset_n,   // Active-low reset
  input wire audio_valid,// Indicates valid audio data is available
  output reg load_en,   // Pulse high to indicate data should be loaded
  output reg ws,        // Word Sync signal (toggles at frame end)
  output reg ready      // Indicates if the controller is ready for new data
);

  reg [7:0] bit_count; // Tracks the current bit position within a frame

  always @(posedge sclk or negedge reset_n) begin
    if (!reset_n) begin
      bit_count <= 8'd0;
      ws <= 1'b0;
      ready <= 1'b1; // Ready to receive data on reset
      load_en <= 1'b0; // Default to not loading
    end else begin
      // load_en is a single-cycle pulse generated on the rising edge of sclk
      load_en <= 1'b0;

      if (sclk) begin // sclk is now high (Rising edge of sclk)
        // Check for start of new frame opportunity
        // Load data if at the start of a frame (bit_count == 0 after rollover),
        // and audio_valid is high, and the controller is ready.
        if (bit_count == 8'd0 && audio_valid && ready) begin
          load_en <= 1'b1; // Assert load enable for one sclk cycle
          ready <= 1'b0; // Not ready for new data while sending this word
        end
      end else begin // sclk is now low (Falling edge of sclk)
        // Update bit_count and perform end-of-frame actions
        if (bit_count == 8'd15) begin
          // End of the 16-bit frame (bit 15 transmitted)
          bit_count <= 8'd0; // Roll over to start a new frame count
          ws <= ~ws;    // Toggle word sync signal
          ready <= 1'b1; // Ready for new data after sending a word
        end else begin
          // Increment bit count for the next bit
          bit_count <= bit_count + 1'b1;
        end
      end
    end
  end
endmodule

// data_path module
// Handles the data shifting and outputting based on control signals.
// Contains the shift register.
module data_path (
  input wire sclk,       // Generated SCLK signal
  input wire reset_n,   // Active-low reset
  input wire [15:0] data_in, // Input audio data
  input wire load_en,   // Load enable signal from frame controller
  output reg sdout      // Serial data output
);

  reg [15:0] shift_reg; // Register holding the data to be transmitted

  always @(posedge sclk or negedge reset_n) begin
    if (!reset_n) begin
      shift_reg <= 16'd0; // Clear shift register on reset
      sdout <= 1'b0; // Clear output on reset
    end else begin
      if (sclk) begin // sclk rising edge
        // Load new data into the shift register if load_en is asserted
        if (load_en) begin
          shift_reg <= data_in;
        end
      end else begin // sclk falling edge
        // Transmit the current MSB of the shift register
        sdout <= shift_reg[15];
        // Shift the register for the next bit
        shift_reg <= {shift_reg[14:0], 1'b0};
      end
    end
  end
endmodule