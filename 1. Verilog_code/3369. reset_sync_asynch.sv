module reset_sync_asynch(
  input  wire clk,
  input  wire arst_n,
  output reg  rst_sync
);
  reg tmp;
  always @(posedge clk or negedge arst_n) begin
    if(!arst_n) begin
      tmp      <= 1'b0;
      rst_sync <= 1'b0;
    end else begin
      tmp      <= 1'b1;
      rst_sync <= tmp;
    end
  end
endmodule
