//SystemVerilog
//==============================================================================
// mipi_dphy_hs_tx
// High-Speed (HS) Transmit Logic for MIPI D-PHY Lane
// Handles data shifting, buffering, and differential output generation
//==============================================================================
module mipi_dphy_hs_tx (
  input wire hs_clk,      // High-speed clock
  input wire reset,      // Synchronous reset
  input wire data_in_bit,// Single data bit input (typically MSB of byte)
  input wire hs_enable,  // Enable for HS mode operation
  output reg hs_out_p,   // Differential positive output
  output reg hs_out_n    // Differential negative output
);

  // Internal shift register to hold the incoming data byte
  // Note: This module only processes one bit per cycle, but the original
  // code had an 8-bit shift register. We'll keep the concept but only
  // use the MSB path if the original intent was to shift a byte over 8 cycles.
  // However, the original code shifted data_in[7] directly into shift_reg[0]
  // and used shift_reg[7] for output, implying a single-bit shift per cycle
  // using the MSB of the incoming byte. We'll adapt this.
  reg [7:0] shift_reg;

  // Buffer register for the output bit of the shift register (shift_reg[7])
  // This is crucial for breaking the critical path from shift_reg[7] to hs_out_p/n.
  // The value of shift_reg[7] from the previous cycle is used to drive outputs
  // in the current cycle.
  reg shift_reg_7_buf;

  always @(posedge hs_clk or posedge reset) begin
    if (reset) begin
      shift_reg <= 8'h00;
      shift_reg_7_buf <= 1'b0; // Reset the buffer register
      hs_out_p <= 1'b0;
      hs_out_n <= 1'b1; // Default state for differential pair (e.g., LP-11 or Hi-Z equiv)
    end else if (hs_enable) begin
      // Shift data: new bit comes into the LSB (shift_reg[0]), MSB (shift_reg[7]) is output
      shift_reg <= {shift_reg[6:0], data_in_bit};

      // Buffer the output bit of the shift register
      // Capture the value of shift_reg[7] *before* the shift in this cycle.
      // This buffered value will be used to drive hs_out_p/n in the *next* cycle.
      shift_reg_7_buf <= shift_reg[7];

      // Drive outputs using the buffered value from the previous cycle
      hs_out_p <= shift_reg_7_buf;
      hs_out_n <= ~shift_reg_7_buf;
    end
    // Note: When hs_enable is deasserted, the outputs and registers hold their last value.
    // A real D-PHY might transition to LP mode or a specific HS state.
    // Following the original code's implicit behavior (no else clause for !hs_enable).
  end

endmodule

//==============================================================================
// mipi_dphy_lp_logic
// Low-Power (LP) Logic for MIPI D-PHY Lane
// Handles generation of LP mode outputs
//==============================================================================
module mipi_dphy_lp_logic (
  input wire lp_clk,      // Low-power clock
  input wire lp_enable,  // Enable for LP mode operation
  output reg [1:0] lp_out // Low-power output state
);

  // Local parameters for LP states (as defined in the original module)
  localparam LP00 = 2'b00, LP01 = 2'b01, LP10 = 2'b10, LP11 = 2'b11;

  always @(posedge lp_clk) begin
    // The original code assigned LP01 when enabled in LP mode.
    // No complex LP state machine was present.
    if (lp_enable) begin
      lp_out <= LP01; // Example LP state (e.g., Start-Stop state)
    end
    // Note: When lp_enable is deasserted, lp_out holds its last value.
    // A real D-PHY might transition to LP11 or Hi-Z.
    // Following the original code's implicit behavior (no else clause for !lp_enable).
  end

endmodule

//==============================================================================
// mipi_dphy_lane_controller (Top Level)
// Top-level module for a MIPI D-PHY Lane Controller
// Instantiates and connects HS TX and LP logic submodules
//==============================================================================
module mipi_dphy_lane_controller (
  input wire hs_clk,      // High-speed clock
  input wire lp_clk,      // Low-power clock
  input wire reset,      // Synchronous reset (primarily for HS logic)
  input wire [7:0] data_in,  // Input data byte (MSB data_in[7] used for HS)
  input wire enable,      // Master enable signal
  input wire hs_mode,    // Mode select: 1 for HS, 0 for LP
  output wire [1:0] lp_out,   // Low-power output signals
  output wire hs_out_p,   // High-speed differential positive output
  output wire hs_out_n    // High-speed differential negative output
);

  // Internal wires for connecting submodules
  wire hs_enable_w;
  wire lp_enable_w;

  // Generate enable signals for submodules based on top-level controls
  assign hs_enable_w = enable && hs_mode;
  assign lp_enable_w = enable && !hs_mode;

  // Instantiate the High-Speed Transmit Logic submodule
  mipi_dphy_hs_tx i_hs_tx (
    .hs_clk      (hs_clk),
    .reset       (reset),
    .data_in_bit (data_in[7]), // Connect the MSB of data_in to the HS TX
    .hs_enable   (hs_enable_w),
    .hs_out_p    (hs_out_p),
    .hs_out_n    (hs_out_n)
  );

  // Instantiate the Low-Power Logic submodule
  mipi_dphy_lp_logic i_lp_logic (
    .lp_clk    (lp_clk),
    .lp_enable (lp_enable_w),
    .lp_out    (lp_out)
  );

  // Note: The original module had an unused 'lp_state' register.
  // It has been removed in this refactored version as it served no function.

endmodule