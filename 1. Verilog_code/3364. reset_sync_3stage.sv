module reset_sync_3stage(
  input  wire clk,
  input  wire rst_n,
  output reg  synced_rst
);
  reg stage1, stage2;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      stage1     <= 1'b0;
      stage2     <= 1'b0;
      synced_rst <= 1'b0;
    end else begin
      stage1     <= 1'b1;
      stage2     <= stage1;
      synced_rst <= stage2;
    end
  end
endmodule
