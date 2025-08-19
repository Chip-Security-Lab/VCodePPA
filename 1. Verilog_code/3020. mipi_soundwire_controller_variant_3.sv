//SystemVerilog
module mipi_soundwire_controller (
  input wire clk,
  input wire reset_n,
  input wire [15:0] audio_in,
  input wire audio_valid,
  output reg sdout,
  output reg sclk,
  output reg ws,
  output reg ready
);

  reg [7:0] bit_count;
  reg [15:0] shift_reg;

  // Combinational logic block representing the "LUT" for sclk rising edge updates
  // Inputs: current state (bit_count, ready, ws), input (audio_valid)
  // Outputs: next values for ready, ws, and shift_reg load enable on sclk rising edge
  reg next_ready_on_sclk_rise;
  reg next_ws_on_sclk_rise;
  reg shift_reg_load_en_sclk_rise;

  always @* begin
    // Default values: hold current state/no load on sclk rising edge
    // These defaults apply when 0 < bit_count < 15
    next_ready_on_sclk_rise = ready;
    next_ws_on_sclk_rise = ws;
    shift_reg_load_en_sclk_rise = 1'b0;

    // Optimized comparison logic based on bit_count value
    // This structure explicitly handles the special cases of the counter
    if (bit_count == 8'd0) begin
      // Logic specific to the start of the frame (bit_count == 0)
      if (audio_valid && ready) begin
        shift_reg_load_en_sclk_rise = 1'b1; // Enable shift_reg loading
        next_ready_on_sclk_rise = 1'b0;       // Set ready low
      end
      // If audio_valid && ready is false, defaults apply:
      // shift_reg_load_en_sclk_rise remains 0
      // next_ready_on_sclk_rise remains 'ready'
    end else if (bit_count == 8'd15) begin
      // Logic specific to the end of the frame (bit_count == 15)
      next_ws_on_sclk_rise = ~ws;         // Toggle ws
      next_ready_on_sclk_rise = 1'b1;       // Set ready high
      // Defaults apply for other signals:
      // shift_reg_load_en_sclk_rise remains 0
    end
    // For any other bit_count value (0 < bit_count < 15), the initial defaults hold.
  end

  // Sequential block to update registers on positive edge of clk or negative edge of reset_n
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      // Reset state
      bit_count <= 8'd0;
      sclk <= 1'b0;
      ws <= 1'b0;
      ready <= 1'b1;
      shift_reg <= 16'b0;
      sdout <= 1'b0;
    end else begin
      // sclk always toggles on every clk edge
      sclk <= ~sclk;

      // Apply updates based on the *previous* value of sclk.
      // This effectively implements logic triggered by sclk edges using the main clk.
      if (!sclk) begin // Previous sclk was 0, next sclk will be 1 (sclk rising edge)
        // Apply updates calculated by the combinational logic for the rising edge
        ready <= next_ready_on_sclk_rise;
        ws <= next_ws_on_sclk_rise;
        if (shift_reg_load_en_sclk_rise) begin
          shift_reg <= audio_in; // Load shift_reg
        end
        // bit_count and sdout do not update on sclk rising edge
      end else begin // Previous sclk was 1, next sclk will be 0 (sclk falling edge)
        // Apply updates for the falling edge (from original 'else' block)
        sdout <= shift_reg[15];                      // Output current bit
        shift_reg <= {shift_reg[14:0], 1'b0};         // Shift right by 1
        bit_count <= (bit_count == 8'd15) ? 8'd0 : bit_count + 1'b1; // Increment/reset counter
        // ws and ready do not update on sclk falling edge
      end
    end
  end

endmodule