module reset_sync_sync_reset(
  input  wire clk,
  input  wire rst_n,
  output reg  sync_rst
);
  reg stage1;
  always @(posedge clk) begin
    if(!rst_n) begin
      stage1   <= 1'b0;
      sync_rst <= 1'b0;
    end else begin
      stage1   <= 1'b1;
      sync_rst <= stage1;
    end
  end
endmodule
