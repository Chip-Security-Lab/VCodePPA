module bidirectional_counter_reset #(parameter WIDTH = 8)(
  input clk, reset, up_down, load, enable,
  input [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] count
);
  always @(posedge clk) begin
    if (reset)
      count <= {WIDTH{1'b0}};
    else if (load)
      count <= data_in;
    else if (enable)
      count <= up_down ? count + 1'b1 : count - 1'b1;
  end
endmodule