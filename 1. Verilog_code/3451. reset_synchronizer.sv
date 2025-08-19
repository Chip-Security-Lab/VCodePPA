module reset_synchronizer (
  input clk,
  input async_reset_n,
  output reg sync_reset_n
);
  reg reset_meta;

  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      reset_meta <= 0;
      sync_reset_n <= 0;
    end else begin
      reset_meta <= 1;
      sync_reset_n <= reset_meta;
    end
  end
endmodule
