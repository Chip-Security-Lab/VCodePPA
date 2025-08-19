module reset_sync_init_val #(parameter INIT_VAL=1'b0)(
  input  wire clk,
  input  wire rst_n,
  output reg  rst_sync
);
  reg flop;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop     <= INIT_VAL;
      rst_sync <= INIT_VAL;
    end else begin
      flop     <= ~INIT_VAL;
      rst_sync <= flop;
    end
  end
endmodule
