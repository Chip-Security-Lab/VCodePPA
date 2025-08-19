module parity_with_error_latch(
  input clk, rst, clear_error,
  input [7:0] data,
  input parity_in,
  output reg error_latched
);
  wire current_error;
  assign current_error = (^data) ^ parity_in;
  
  always @(posedge clk) begin
    if (rst)
      error_latched <= 1'b0;
    else if (clear_error)
      error_latched <= 1'b0;
    else if (current_error)
      error_latched <= 1'b1;
  end
endmodule