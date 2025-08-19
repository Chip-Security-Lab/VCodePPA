//SystemVerilog
module reset_synchronizer (
  input wire clk,
  input wire async_reset_n,
  output reg sync_reset_n
);
  (* dont_touch = "true" *) (* ASYNC_REG = "TRUE" *) reg [2:0] reset_meta;

  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      reset_meta <= 3'b000;
    end else begin
      reset_meta <= {reset_meta[1:0], 1'b1};
    end
  end

  always @(*) begin
    sync_reset_n = reset_meta[2];
  end
endmodule