//SystemVerilog
module reset_generator_debounce #(parameter DEBOUNCE_LEN = 4)(
  input clk, button_in,
  output reg reset_out
);
  reg [DEBOUNCE_LEN-1:0] debounce_reg;
  wire all_ones, all_zeros;
  
  assign all_ones = &debounce_reg;
  assign all_zeros = ~|debounce_reg;
  
  always @(posedge clk) begin
    debounce_reg <= {debounce_reg[DEBOUNCE_LEN-2:0], button_in};
    
    case ({all_ones, all_zeros})
      2'b10:   reset_out <= 1'b1;
      2'b01:   reset_out <= 1'b0;
      default: reset_out <= reset_out;
    endcase
  end
endmodule