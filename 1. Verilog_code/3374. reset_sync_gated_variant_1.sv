//SystemVerilog
module reset_sync_gated(
  input  wire clk,
  input  wire gate_en,
  input  wire rst_n,
  output reg  synced_rst
);
  reg gate_en_r;
  reg gate_en_r2;
  
  // Register the input control signal to reduce fanout and improve timing
  always @(posedge clk or negedge rst_n) begin
    gate_en_r  <= !rst_n ? 1'b0 : gate_en;
    gate_en_r2 <= !rst_n ? 1'b0 : gate_en_r;
    synced_rst <= !rst_n ? 1'b0 : gate_en_r2;
  end
endmodule