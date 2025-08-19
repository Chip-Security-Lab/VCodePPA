module reset_generator_debounce #(parameter DEBOUNCE_LEN = 4)(
  input clk, button_in,
  output reg reset_out
);
  reg [DEBOUNCE_LEN-1:0] debounce_reg;
  
  always @(posedge clk) begin
    debounce_reg <= {debounce_reg[DEBOUNCE_LEN-2:0], button_in};
    if (&debounce_reg)
      reset_out <= 1'b1;
    else if (~|debounce_reg)
      reset_out <= 1'b0;
  end
endmodule