module sync_reset_counter #(parameter WIDTH = 8)(
  input clk, rst_n, enable,
  output reg [WIDTH-1:0] count
);
  always @(posedge clk) begin
    if (!rst_n)
      count <= {WIDTH{1'b0}};
    else if (enable)
      count <= count + 1'b1;
  end
endmodule