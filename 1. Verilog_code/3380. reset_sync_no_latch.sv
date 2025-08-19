module reset_sync_no_latch(
  input  wire clk,
  input  wire rst_n,
  output reg  synced
);
  reg st;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      st     <= 1'b0;
      synced <= 1'b0;
    end else begin
      st     <= 1'b1;
      synced <= st;
    end
  end
endmodule
