//SystemVerilog
module mipi_mphy_clock_gen_pipelined #(parameter GEAR = 4)(
  input wire ref_clk, reset_n,
  input wire [1:0] speed_mode, // 00: LS, 01: HS-G1, 10: HS-G2, 11: HS-G3
  input wire enable,
  output wire tx_clk,
  output wire [GEAR-1:0] tx_symbol_clk,
  output wire pll_lock
);

  // Stage 1: Decode speed_mode to get divider, Register inputs
  reg [1:0] speed_mode_s1_reg;
  reg enable_s1_reg;
  reg [3:0] divider_s1_comb; // Needs 4 bits for max divider 12

  reg [3:0] divider_s1_out_reg;
  reg enable_s1_out_reg;
  reg valid_s1_reg; // Valid signal for Stage 1 output

  // Stage 2: Counter, Clock and Lock Generation, Register outputs
  reg [3:0] divider_s2_reg; // Needs 4 bits
  reg enable_s2_reg;
  reg valid_s2_reg; // Valid signal for Stage 2 output

  reg [3:0] counter_s2_reg; // Needs 4 bits for max count 11
  reg [3:0] counter_s2_next_comb;

  reg tx_clk_s2_comb;
  reg pll_lock_s2_comb;
  reg tx_symbol_clk_s2_comb; // Single bit symbol clock logic

  reg tx_clk_out_reg;
  reg [GEAR-1:0] tx_symbol_clk_out_reg;
  reg pll_lock_out_reg;

  // Stage 1 Combinational Logic: Calculate divider
  always @(*) begin
    case (speed_mode)
      2'b00: divider_s1_comb = 4'd12; // LS
      2'b01: divider_s1_comb = 4'd6;  // HS-G1
      2'b10: divider_s1_comb = 4'd3;  // HS-G2
      2'b11: divider_s1_comb = 4'd2;  // HS-G3
      default: divider_s1_comb = 4'd10; // Default divider
    endcase
  end

  // Stage 2 Combinational Logic: Counter, Clocks, Lock
  always @(*) begin
    // Counter update logic
    if (counter_s2_reg == divider_s2_reg - 1) begin
      counter_s2_next_comb = 4'd0;
    end else begin
      counter_s2_next_comb = counter_s2_reg + 1'b1;
    end

    // tx_clk generation logic
    tx_clk_s2_comb = (counter_s2_reg < divider_s2_reg / 2);

    // pll_lock generation logic
    // In this model, lock is asserted when enabled in this stage
    pll_lock_s2_comb = enable_s2_reg;

    // tx_symbol_clk generation logic (Example: pulse when counter wraps)
    // This is a simplified assumption based on the output port definition.
    // A real MPHY symbol clock might be generated differently.
    tx_symbol_clk_s2_comb = (counter_s2_reg == divider_s2_reg - 1);
  end

  // Pipeline Registers
  always @(posedge ref_clk or negedge reset_n) begin
    if (!reset_n) begin
      // Stage 1 Reset
      speed_mode_s1_reg <= 2'b00;
      enable_s1_reg <= 1'b0;
      divider_s1_out_reg <= 4'd10; // Default divider on reset
      enable_s1_out_reg <= 1'b0;
      valid_s1_reg <= 1'b0;

      // Stage 2 Reset
      divider_s2_reg <= 4'd10; // Default divider on reset
      enable_s2_reg <= 1'b0;
      valid_s2_reg <= 1'b0;
      counter_s2_reg <= 4'd0;
      tx_clk_out_reg <= 1'b0;
      tx_symbol_clk_out_reg <= {(GEAR){1'b0}};
      pll_lock_out_reg <= 1'b0;

    end else begin
      // Stage 1 Registers Update
      speed_mode_s1_reg <= speed_mode; // Register input speed_mode
      enable_s1_reg <= enable;         // Register input enable

      // Pass Stage 1 combinational output and registered input to Stage 2
      divider_s1_out_reg <= divider_s1_comb;
      enable_s1_out_reg <= enable_s1_reg;
      valid_s1_reg <= enable_s1_reg; // Data is valid if enable was high

      // Stage 2 Registers Update
      // Pass data and valid from Stage 1 output registers
      divider_s2_reg <= divider_s1_out_reg;
      enable_s2_reg <= enable_s1_out_reg;
      valid_s2_reg <= valid_s1_reg;

      // Stage 2 State Update (Counter, Clocks, Lock) - Update only if valid and enabled
      if (valid_s2_reg && enable_s2_reg) begin
        counter_s2_reg <= counter_s2_next_comb; // Update counter based on combinational logic
        tx_clk_out_reg <= tx_clk_s2_comb;     // Update tx_clk based on combinational logic
        pll_lock_out_reg <= pll_lock_s2_comb; // Update pll_lock
        tx_symbol_clk_out_reg <= {(GEAR){tx_symbol_clk_s2_comb}}; // Update tx_symbol_clk
      end else begin
        // If not valid or not enabled in this stage, reset state
        counter_s2_reg <= 4'd0;
        tx_clk_out_reg <= 1'b0;
        pll_lock_out_reg <= 1'b0;
        tx_symbol_clk_out_reg <= {(GEAR){1'b0}};
      end
    end
  end

  // Output assignments from output registers
  assign tx_clk = tx_clk_out_reg;
  assign tx_symbol_clk = tx_symbol_clk_out_reg;
  assign pll_lock = pll_lock_out_reg;

endmodule