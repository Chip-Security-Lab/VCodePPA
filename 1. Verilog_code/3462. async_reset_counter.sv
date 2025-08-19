module async_reset_counter #(parameter WIDTH = 16)(
  input clk, rst_n, enable,
  output reg [WIDTH-1:0] counter
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      counter <= {WIDTH{1'b0}};
    else if (enable)
      counter <= counter + 1'b1;
  end
endmodule