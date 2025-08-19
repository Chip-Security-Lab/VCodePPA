//SystemVerilog
module reset_with_enable_priority #(parameter WIDTH = 4)(
  input clk, rst, en,
  output reg [WIDTH-1:0] data_out
);
  wire [WIDTH-1:0] next_data;
  
  // Direct computation of next_data from output rather than using internal register
  assign next_data = data_out + 1;
  
  // Single register implementation with enable logic
  always @(posedge clk) begin
    if (rst)
      data_out <= {WIDTH{1'b0}};
    else if (en)
      data_out <= next_data;
  end
endmodule