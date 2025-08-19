module debouncer_reset #(parameter DELAY = 16)(
  input clk, rst, button_in,
  output reg button_out
);
  reg [DELAY-1:0] shift_reg;
  
  always @(posedge clk) begin
    if (rst) begin
      shift_reg <= {DELAY{1'b0}};
      button_out <= 1'b0;
    end else begin
      shift_reg <= {shift_reg[DELAY-2:0], button_in};
      if (&shift_reg)
        button_out <= 1'b1;
      else if (~|shift_reg)
        button_out <= 1'b0;
    end
  end
endmodule