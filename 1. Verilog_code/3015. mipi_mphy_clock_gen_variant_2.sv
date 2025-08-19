//SystemVerilog
module mipi_mphy_clock_gen #(parameter GEAR = 4)(
  input wire ref_clk, reset_n,
  input wire [1:0] speed_mode, // 00: LS, 01: HS-G1, 10: HS-G2, 11: HS-G3
  input wire enable,
  output wire tx_clk,
  output wire [GEAR-1:0] tx_symbol_clk,
  output wire pll_lock
);

  // Stage 1 Registers: Capture inputs, calculate divider and pll_lock
  reg enable_s1_reg;
  reg [1:0] speed_mode_s1_reg;
  reg [3:0] divider_s1_reg;
  reg pll_lock_s1_reg;

  // Stage 2 Registers: Register Stage 1 outputs, holds the main counter state
  reg enable_s2_reg;
  reg [3:0] divider_s2_reg;
  reg pll_lock_s2_reg;
  reg [3:0] counter_s2_reg; // Main counter state - Increased size to [3:0] for divider=12

  // Stage 3 Register: Holds the final tx_clk output (retimed)
  reg tx_clk_reg; // Retimed tx_clk output register

  // Combinational wires for intermediate calculations
  wire [3:0] divider_half_comb; // Half divider value calculated from Stage 2 register
  wire [3:0] next_counter_comb; // Next counter value calculated from Stage 2 register
  wire tx_clk_comb; // Combinational logic output for tx_clk

  // --- Stage 1: Input Registering and Divider/PLL_lock Calc ---
  // Registers inputs and calculates the desired divider and pll_lock values based on enable and speed_mode.
  always @(posedge ref_clk or negedge reset_n) begin
    if (!reset_n) begin
      enable_s1_reg <= 1'b0;
      speed_mode_s1_reg <= 2'b00;
      divider_s1_reg <= 4'd10; // Default divider
      pll_lock_s1_reg <= 1'b0;
    end else begin
      enable_s1_reg <= enable;
      speed_mode_s1_reg <= speed_mode;
      if (enable) begin
        case (speed_mode)
          2'b00: divider_s1_reg <= 4'd12;
          2'b01: divider_s1_reg <= 4'd6;
          2'b10: divider_s1_reg <= 4'd3;
          2'b11: divider_s1_reg <= 4'd2;
          default: divider_s1_reg <= 4'd10; // Should not happen with 2 bits input
        endcase
        pll_lock_s1_reg <= 1'b1;
      end
      // If enable is low, divider_s1_reg and pll_lock_s1_reg hold their values (due to lack of update in else branch)
    end
  end

  // --- Stage 2: Register Stage 1 outputs, Counter Update, Half Divider Calc ---
  // Registers the outputs from Stage 1.
  // Updates the main counter state (`counter_s2_reg`) based on the enable and divider values from Stage 1 (now in S2 registers).
  // Calculates the half divider value combinatorially.
  always @(posedge ref_clk or negedge reset_n) begin
      if (!reset_n) begin
          enable_s2_reg <= 1'b0;
          divider_s2_reg <= 4'd10;
          pll_lock_s2_reg <= 1'b0;
          counter_s2_reg <= 4'd0; // Reset counter state
      end else begin
          // Register values from Stage 1
          enable_s2_reg <= enable_s1_reg;
          divider_s2_reg <= divider_s1_reg;
          pll_lock_s2_reg <= pll_lock_s1_reg;

          // Update counter state only when enable is active (after 1 stage latency)
          if (enable_s2_reg) begin
              counter_s2_reg <= next_counter_comb;
          end
          // If enable_s2_reg is low, counter_s2_reg holds its value.
      end
  end

  // Combinational logic for Stage 2: Calculate next counter value and half divider
  assign divider_half_comb = divider_s2_reg / 2;
  assign next_counter_comb = (counter_s2_reg == divider_s2_reg - 1) ? 4'd0 : counter_s2_reg + 1'b1;

  // --- Stage 3: TX_CLK Calculation and Registering (Retimed) ---
  // Calculates the tx_clk value combinatorially based on Stage 2 registered values (counter_s2_reg)
  // and Stage 2 combinatorial value (divider_half_comb).
  // Registers the final tx_clk value for output.

  // Combinational logic for tx_clk based on Stage 2 counter and half divider
  // This logic was previously after Stage 3 registers, now it's before the retimed tx_clk register
  assign tx_clk_comb = (counter_s2_reg < divider_half_comb) ? 1'b1 : 1'b0;

  // Register the final tx_clk output
  // This register was tx_clk_s3_reg in the original code, now fed directly by the comparator logic
  always @(posedge ref_clk or negedge reset_n) begin
      if (!reset_n) begin
          tx_clk_reg <= 1'b0; // Reset tx_clk output
      end else begin
          tx_clk_reg <= tx_clk_comb; // Register the calculated combinatorial value
      end
  end

  // --- Outputs ---
  // Assign pipeline stage outputs to module outputs
  assign tx_clk = tx_clk_reg; // Final tx_clk from retimed output register
  assign pll_lock = pll_lock_s2_reg; // Output pll_lock from Stage 2 register (reflects enable with 2-cycle latency)
  assign tx_symbol_clk = {GEAR{1'b0}}; // tx_symbol_clk was not driven in original code; assign default 0s.

endmodule