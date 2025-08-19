//SystemVerilog
module reset_sync_gated(
  input  wire clk,
  input  wire gate_en,
  input  wire rst_n,
  output reg  synced_rst
);
  reg flp1, flp2;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flp1 <= 1'b0;
      flp2 <= 1'b0;
      synced_rst <= 1'b0;
    end else begin
      flp1 <= gate_en;
      flp2 <= flp1 & gate_en;
      synced_rst <= flp2;
    end
  end
endmodule