module reset_sync_basic(
  input  wire clk,
  input  wire async_rst_n,
  output reg  sync_rst_n
);
  reg stage1;
  always @(posedge clk or negedge async_rst_n) begin
    if(!async_rst_n) begin
      stage1     <= 1'b0;
      sync_rst_n <= 1'b0;
    end else begin
      stage1     <= 1'b1;
      sync_rst_n <= stage1;
    end
  end
endmodule
