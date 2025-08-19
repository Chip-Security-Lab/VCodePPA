//SystemVerilog
// Top module for the MIPI MPHY Clock Generator
// Instantiates submodules for configuration, clock generation, and status
module mipi_mphy_clock_gen #(parameter GEAR = 4)(
  input wire ref_clk,
  input wire reset_n,
  input wire [1:0] speed_mode, // 00: LS, 01: HS-G1, 10: HS-G2, 11: HS-G3
  input wire enable,
  output wire tx_clk,
  output reg [GEAR-1:0] tx_symbol_clk, // Original code doesn't assign this
  output wire pll_lock
);

  // Internal signals connecting submodules
  wire [3:0] w_divider; // Wire for the calculated divider value

  // Instantiate the divider configuration module
  mipi_mphy_divider_config i_divider_config (
    .ref_clk    (ref_clk),
    .reset_n    (reset_n),
    .enable     (enable),
    .speed_mode (speed_mode),
    .divider    (w_divider)
  );

  // Instantiate the clock generation core module (Pipelined Version)
  mipi_mphy_clk_generator_core_pipelined i_clk_generator (
    .ref_clk  (ref_clk),
    .reset_n  (reset_n),
    .enable   (enable),
    .divider  (w_divider),
    .tx_clk   (tx_clk)
  );

  // Instantiate the status logic module
  mipi_mphy_status_logic i_status_logic (
    .ref_clk  (ref_clk),
    .reset_n  (reset_n),
    .enable   (enable),
    .pll_lock (pll_lock)
  );

  // Handle tx_symbol_clk: Original code does not assign this output.
  // Assigning a default value (like 0) for synthesis compatibility,
  // maintaining the original functional behavior of not generating this clock.
  always @(*) begin
      tx_symbol_clk = {GEAR{1'b0}}; // Assign all bits to 0
  end

endmodule


// Module to determine the clock division factor based on speed mode
// (Unchanged - already sequential and simple)
module mipi_mphy_divider_config (
  input wire ref_clk,
  input wire reset_n,
  input wire enable,
  input wire [1:0] speed_mode,
  output reg [3:0] divider
);

  // The divider register is updated synchronously based on ref_clk
  always @(posedge ref_clk or negedge reset_n) begin
    if (!reset_n) begin
      divider <= 4'd10; // Default divider value on reset
    end else if (enable) begin
      // Update divider based on speed_mode when enabled
      case (speed_mode)
        2'b00: divider <= 4'd12; // LS mode division factor
        2'b01: divider <= 4'd6;  // HS-G1 mode division factor
        2'b10: divider <= 4'd3;  // HS-G2 mode division factor
        2'b11: divider <= 4'd2;  // HS-G3 mode division factor
        default: divider <= 4'd10; // Fallback for undefined speed_mode
      endcase
    end
    // If enable is low, the divider holds its last value, matching original behavior.
  end

endmodule


// Module to generate the divided clock (tx_clk) - Pipelined Version
// Increased pipeline depth to improve Fmax
module mipi_mphy_clk_generator_core_pipelined (
  input wire ref_clk,
  input wire reset_n,
  input wire enable,
  input wire [3:0] divider,
  output wire tx_clk
);

  // Pipelined Registers
  // Stage 0: Input Registration
  reg enable_s1;
  reg [3:0] divider_s1;

  // Stage 1: Intermediate Calculation Registration
  reg enable_s2;
  reg [3:0] divider_s2;
  reg counter_wrap_s2; // Result of counter_reg_s3 == (divider_s1 - 1)
  reg tx_clk_val_s2;   // Result of counter_reg_s3 < (divider_s1 / 2)
  reg [3:0] counter_plus_1_s2; // Result of counter_reg_s3 + 1

  // Stage 2: Next State/Output Calculation Registration
  reg enable_s3;
  reg [3:0] next_counter_s3; // Result of (counter_wrap_s2 ? 0 : counter_plus_1_s2)
  reg tx_clk_val_s3;   // Result of tx_clk_val_s2

  // Stage 3: State and Output Registration
  reg [3:0] counter_reg_s3; // The actual counter state
  reg tx_clk_reg_s3; // The final tx_clk output register


  // Stage 0: Register Inputs
  always @(posedge ref_clk or negedge reset_n) begin
    if (!reset_n) begin
      enable_s1 <= 1'b0;
      divider_s1 <= 4'd1; // Use a safe default
    end else begin
      enable_s1 <= enable;
      divider_s1 <= divider;
    end
  end

  // Stage 1: Compute Intermediate Values and Register
  // Calculations based on counter_reg_s3 and divider_s1
  wire [3:0] divider_minus_1_s1_comb = (divider_s1 > 0) ? divider_s1 - 1 : 4'd0;
  wire [3:0] divider_half_s1_comb    = (divider_s1 > 0) ? divider_s1 / 2 : 4'd0; // Integer division

  wire counter_eq_divider_minus_1_s1_comb = (counter_reg_s3 == divider_minus_1_s1_comb);
  wire counter_lt_divider_half_s1_comb    = (counter_reg_s3 < divider_half_s1_comb);
  wire [3:0] counter_plus_1_s1_comb       = counter_reg_s3 + 1'b1; // Always compute +1


  always @(posedge ref_clk or negedge reset_n) begin
    if (!reset_n) begin
      enable_s2 <= 1'b0;
      divider_s2 <= 4'd1;
      counter_wrap_s2 <= 1'b0;
      tx_clk_val_s2 <= 1'b0;
      counter_plus_1_s2 <= 4'd0;
    end else if (enable_s1) begin // Only update stage registers if enable_s1 is high
      enable_s2 <= 1'b1; // Propagate high enable
      divider_s2 <= divider_s1;
      counter_wrap_s2 <= counter_eq_divider_minus_1_s1_comb;
      tx_clk_val_s2 <= counter_lt_divider_half_s1_comb;
      counter_plus_1_s2 <= counter_plus_1_s1_comb;
    end else begin // If enable_s1 is low, hold state in stage 1 registers
      enable_s2 <= 1'b0; // Propagate low enable
      // Hold previous values
    end
  end

  // Stage 2: Compute Next State and Output Values and Register
  // Calculations based on stage 1 registered values
  wire [3:0] next_counter_s2_comb = counter_wrap_s2 ? 4'd0 : counter_plus_1_s2;

  always @(posedge ref_clk or negedge reset_n) begin
    if (!reset_n) begin
      enable_s3 <= 1'b0;
      next_counter_s3 <= 4'd0;
      tx_clk_val_s3 <= 1'b0;
    end else if (enable_s2) begin // Only update stage registers if enable_s2 is high
      enable_s3 <= 1'b1; // Propagate high enable
      next_counter_s3 <= next_counter_s2_comb;
      tx_clk_val_s3 <= tx_clk_val_s2;
    end else begin // If enable_s2 is low, hold state in stage 2 registers
      enable_s3 <= 1'b0; // Propagate low enable
      // Hold previous values
    end
  end

  // Stage 3: Update State and Output Registers
  // Updates based on stage 2 registered values and enable_s3
  always @(posedge ref_clk or negedge reset_n) begin
    if (!reset_n) begin
      counter_reg_s3 <= 4'd0;
      tx_clk_reg_s3 <= 1'b0;
    end else if (enable_s3) begin // Only update final registers if enable_s3 is high
       if (divider_s2 > 0) begin // Check divider validity from appropriate stage (used in stage 1)
          counter_reg_s3 <= next_counter_s3;
          tx_clk_reg_s3 <= tx_clk_val_s3;
       end else begin // divider_s2 is 0, reset state
          counter_reg_s3 <= 4'd0;
          tx_clk_reg_s3 <= 1'b0;
       end
    end else begin // If enable_s3 is low, hold state in final registers
      // Hold previous values
    end
  end

  assign tx_clk = tx_clk_reg_s3;

endmodule


// Module to generate the PLL lock status signal
// (Unchanged - already sequential and simple)
module mipi_mphy_status_logic (
  input wire ref_clk,
  input wire reset_n,
  input wire enable,
  output reg pll_lock
);

  // Generate a simple simulated PLL lock signal
  always @(posedge ref_clk or negedge reset_n) begin
    if (!reset_n) begin
      pll_lock <= 1'b0; // PLL is not locked on reset
    end else if (enable) begin
      // Simulate lock when the clock generator is enabled
      pll_lock <= 1'b1;
    end
    // If enable is low, pll_lock holds its last value (which would be 1 if it was enabled before), matching original behavior.
  end

endmodule