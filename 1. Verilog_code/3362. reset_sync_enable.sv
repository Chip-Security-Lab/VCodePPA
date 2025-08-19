module reset_sync_enable(
  input  wire clk,
  input  wire en,
  input  wire rst_n,
  output reg  sync_reset
);
  reg flop1;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop1     <= 1'b0;
      sync_reset <= 1'b0;
    end else if(en) begin
      flop1     <= 1'b1;
      sync_reset <= flop1;
    end
  end
endmodule
