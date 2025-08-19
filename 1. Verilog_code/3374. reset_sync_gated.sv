module reset_sync_gated(
  input  wire clk,
  input  wire gate_en,
  input  wire rst_n,
  output reg  synced_rst
);
  reg flp;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flp        <= 1'b0;
      synced_rst <= 1'b0;
    end else if(gate_en) begin
      flp        <= 1'b1;
      synced_rst <= flp;
    end
  end
endmodule
