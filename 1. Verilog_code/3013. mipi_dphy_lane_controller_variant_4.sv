//SystemVerilog
module mipi_dphy_lane_controller (
  input wire hs_clk, lp_clk, reset,
  input wire [7:0] data_in,
  input wire enable, hs_mode,
  output reg [1:0] lp_out,
  output reg hs_out_p, hs_out_n
);
  localparam LP00 = 2'b00, LP01 = 2'b01, LP10 = 2'b10, LP11 = 2'b11;
  reg [2:0] lp_state; // This signal is unused in the original code, keeping it for equivalence
  reg [7:0] shift_reg;
  
  // HS mode logic
  always @(posedge hs_clk or posedge reset) begin
    if (reset) begin
      shift_reg <= 8'h00;
      hs_out_p <= 1'b0;
      hs_out_n <= 1'b1;
    end else begin
      // Logic is enabled only when hs_mode and enable are high
      if (hs_mode && enable) begin
        shift_reg <= {shift_reg[6:0], data_in[7]};
        // Outputs reflect the state of the shift register *before* the shift
        hs_out_p <= shift_reg[7];
        hs_out_n <= ~shift_reg[7];
      end
      // If not enabled, shift_reg, hs_out_p, hs_out_n hold their values
    end
  end
  
  // LP mode logic
  always @(posedge lp_clk) begin
    // lp_out is updated only when enable is high and hs_mode is low
    if (enable && !hs_mode) begin
      lp_out <= LP01;
    end
    // If condition is false, lp_out holds its value
  end
  
endmodule