module sync_parity_checker(
  input clk, rst,
  input [7:0] data,
  input parity_in,
  output reg error,
  output reg [3:0] error_count
);
  always @(posedge clk) begin
    if (rst) begin
      error <= 1'b0;
      error_count <= 4'd0;
    end else begin
      error <= (^data) ^ parity_in;
      if ((^data) ^ parity_in)
        error_count <= error_count + 1'b1;
    end
  end
endmodule