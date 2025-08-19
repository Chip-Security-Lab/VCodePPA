//SystemVerilog
module mipi_dphy_lane_controller (
  input wire hs_clk, lp_clk, reset,
  input wire [7:0] data_in,
  input wire enable, hs_mode,
  output reg [1:0] lp_out,
  output reg hs_out_p, hs_out_n
);

  localparam LP00 = 2'b00, LP01 = 2'b01, LP10 = 2'b10, LP11 = 2'b11;

  //----------------------------------------------------------------
  // LP Mode Logic (Operates on lp_clk, not pipelined)
  // This logic block is kept separate as it's on a different clock domain.
  //----------------------------------------------------------------
  always @(posedge lp_clk or posedge reset) begin // Added reset to LP block for completeness
    if (reset) begin
      lp_out <= LP00; // Assuming LP00 is a safe reset state
    end else if (enable && !hs_mode) begin
      lp_out <= LP01;
    end else begin // Explicitly handle the case when not reset and not active
      // lp_out holds its value (implicit in original, explicit here for clarity)
      // No assignment means it retains its value.
    end
  end

  //----------------------------------------------------------------
  // HS Mode Logic (Operates on hs_clk, pipelined)
  // Pipelined into 2 stages to reduce critical path and increase fmax.
  // Merged all HS always blocks into a single block for better structure.
  //----------------------------------------------------------------

  // Pipeline registers holding data from Stage 0 for Stage 1
  reg enable_stage1_reg;
  reg hs_mode_stage1_reg;
  reg data_in_bit_stage1_reg;
  reg valid_stage1_reg; // Indicates valid data entering Stage 1

  // Pipeline registers holding data from Stage 1 for Stage 2
  reg [7:0] shift_reg_stage2_reg; // State of the shift register after Stage 1
  reg valid_stage2_reg; // Indicates valid data entering Stage 2

  // Combined HS Pipeline Logic (Stage 0, Stage 1, Stage 2)
  always @(posedge hs_clk or posedge reset) begin
    if (reset) begin
      // Reset Stage 0 registers
      enable_stage1_reg <= 1'b0;
      hs_mode_stage1_reg <= 1'b0;
      data_in_bit_stage1_reg <= 1'b0;
      valid_stage1_reg <= 1'b0;

      // Reset Stage 1 registers
      shift_reg_stage2_reg <= 8'h00;
      valid_stage2_reg <= 1'b0;

      // Reset Stage 2 outputs
      hs_out_p <= 1'b0;
      hs_out_n <= 1'b1; // Default/Reset state for HS outputs
    end else begin
      // Stage 0: Input Latching (Registers for Stage 1 inputs)
      // Latches module inputs relevant to the HS path on hs_clk.
      enable_stage1_reg <= enable;
      hs_mode_stage1_reg <= hs_mode;
      data_in_bit_stage1_reg <= data_in[7];
      // Data is considered valid for the HS pipeline if enable and hs_mode are active.
      valid_stage1_reg <= enable && hs_mode;

      // Stage 1: Shift Register Update (Registers for Stage 2 inputs)
      // Performs the shift operation based on latched inputs from Stage 0.
      // Update shift register only if valid data is provided from Stage 0.
      if (valid_stage1_reg) begin
        shift_reg_stage2_reg <= {shift_reg_stage2_reg[6:0], data_in_bit_stage1_reg};
      end
      // Propagate the validity signal to the next stage.
      valid_stage2_reg <= valid_stage1_reg;
      // If valid_stage1_reg is low, shift_reg_stage2_reg holds its value,
      // effectively stopping the shift process when the pipeline is not fed.

      // Stage 2: Output Generation (Registers for module outputs)
      // Generates final HS outputs based on the registered state from Stage 1.
      // Update outputs only if valid data is provided from Stage 1.
      if (valid_stage2_reg) begin
        hs_out_p <= shift_reg_stage2_reg[7];
        hs_out_n <= ~shift_reg_stage2_reg[7];
      end
      // If valid_stage2_reg is low, hs_out_p and hs_out_n hold their values.
      // This maintains the last valid output state when the pipeline stalls or finishes.
    end
  end

endmodule