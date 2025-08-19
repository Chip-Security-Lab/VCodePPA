//SystemVerilog
module RD10 #(parameter BITS=8)(
  input clk, input rst, input en,
  input [BITS-1:0] in_val,
  output reg [BITS-1:0] out_val
);
  
  // Apply backward register retiming to move registers closer to inputs
  // and push through combinational logic
  
  reg rst_reg, en_reg;
  reg [BITS-1:0] rst_val, en_val, default_val;
  
  // Register control signals and pre-compute possible output values
  always @(posedge clk) begin
    rst_reg <= rst;
    en_reg <= en;
    
    // Pre-compute all possible output values
    rst_val <= {BITS{1'b0}};          // Reset value
    en_val <= in_val;                 // Enabled value
    default_val <= {BITS{1'b0}};      // Default value
  end
  
  // Register the output based on registered control signals
  always @(posedge clk) begin
    if (rst_reg)
      out_val <= rst_val;
    else if (en_reg)
      out_val <= en_val;
    else
      out_val <= default_val;
  end
  
endmodule