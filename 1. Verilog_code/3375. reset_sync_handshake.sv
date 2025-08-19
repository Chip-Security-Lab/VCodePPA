module reset_sync_handshake(
  input  wire clk,
  input  wire rst_n,
  input  wire rst_valid,
  output reg  rst_done
);
  reg sync_flop;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sync_flop <= 1'b0;
      rst_done  <= 1'b0;
    end else if(rst_valid) begin
      sync_flop <= 1'b1;
      rst_done  <= sync_flop;
    end
  end
endmodule
