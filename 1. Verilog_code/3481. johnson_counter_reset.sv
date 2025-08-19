module johnson_counter_reset #(parameter WIDTH = 8)(
  input clk, rst, enable,
  output reg [WIDTH-1:0] johnson_count
);
  always @(posedge clk) begin
    if (rst)
      johnson_count <= {{WIDTH-1{1'b0}}, 1'b1};
    else if (enable)
      johnson_count <= {johnson_count[WIDTH-2:0], ~johnson_count[WIDTH-1]};
  end
endmodule