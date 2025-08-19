module dual_reset_counter #(parameter WIDTH = 8)(
  input clk, sync_rst, async_rst_n, enable,
  output reg [WIDTH-1:0] count
);
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n)
      count <= {WIDTH{1'b0}};
    else if (sync_rst)
      count <= {WIDTH{1'b0}};
    else if (enable)
      count <= count + 1'b1;
  end
endmodule