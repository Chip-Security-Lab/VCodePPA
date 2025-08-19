module param_register_reset #(
  parameter WIDTH = 16,
  parameter RESET_VALUE = 16'hFFFF
)(
  input clk, rst_n, load,
  input [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] data_out
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      data_out <= RESET_VALUE;
    else if (load)
      data_out <= data_in;
  end
endmodule