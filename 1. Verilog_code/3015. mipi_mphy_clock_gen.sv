module mipi_mphy_clock_gen #(parameter GEAR = 4)(
  input wire ref_clk, reset_n,
  input wire [1:0] speed_mode, // 00: LS, 01: HS-G1, 10: HS-G2, 11: HS-G3
  input wire enable,
  output reg tx_clk,
  output reg [GEAR-1:0] tx_symbol_clk,
  output reg pll_lock
);
  reg [3:0] divider;
  reg [2:0] counter;
  
  always @(posedge ref_clk or negedge reset_n) begin
    if (!reset_n) begin
      divider <= 4'd10; // Default divider
      pll_lock <= 1'b0;
      counter <= 3'd0;
    end else if (enable) begin
      case (speed_mode)
        2'b00: divider <= 4'd12;
        2'b01: divider <= 4'd6;
        2'b10: divider <= 4'd3;
        2'b11: divider <= 4'd2;
      endcase
      pll_lock <= 1'b1;
      counter <= (counter == divider-1) ? 3'd0 : counter + 1'b1;
      tx_clk <= (counter < divider/2) ? 1'b1 : 1'b0;
    end
  end
endmodule
