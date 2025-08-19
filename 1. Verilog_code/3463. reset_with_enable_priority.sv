module reset_with_enable_priority #(parameter WIDTH = 4)(
  input clk, rst, en,
  output reg [WIDTH-1:0] data_out
);
  reg [WIDTH-1:0] internal_data;
  always @(posedge clk) begin
    if (rst)
      internal_data <= {WIDTH{1'b0}};
    else if (en)
      internal_data <= internal_data + 1;
    data_out <= internal_data;
  end
endmodule