//SystemVerilog
module reset_generator_debounce #(parameter DEBOUNCE_LEN = 4)(
  input clk, button_in,
  output reg reset_out
);
  reg [DEBOUNCE_LEN-1:0] debounce_reg;
  reg all_ones, all_zeros;
  
  always @(posedge clk) begin
    // Move register through combinational logic
    debounce_reg <= {debounce_reg[DEBOUNCE_LEN-2:0], button_in};
    
    // Pre-compute conditions and register them
    all_ones <= &{debounce_reg[DEBOUNCE_LEN-2:0], button_in};
    all_zeros <= ~|{debounce_reg[DEBOUNCE_LEN-2:0], button_in};
    
    // Use registered conditions for output
    if (all_ones)
      reset_out <= 1'b1;
    else if (all_zeros)
      reset_out <= 1'b0;
  end
endmodule