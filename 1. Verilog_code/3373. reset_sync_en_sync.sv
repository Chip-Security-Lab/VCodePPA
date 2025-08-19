module reset_sync_en_sync(
  input  wire clk,
  input  wire en,
  input  wire rst_n,
  output reg  rst_sync
);
  reg stage;
  always @(posedge clk) begin
    if(!rst_n) begin
      stage    <= 1'b0;
      rst_sync <= 1'b0;
    end else if(en) begin
      stage    <= 1'b1;
      rst_sync <= stage;
    end
  end
endmodule
