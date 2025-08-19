module reset_source_control(
  input clk, master_rst_n,
  input [7:0] reset_sources, // Active high reset signals
  input [7:0] enable_mask, // 1=enabled, 0=disabled
  output reg [7:0] reset_status,
  output reg system_reset
);
  wire [7:0] masked_sources = reset_sources & enable_mask;
  
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      reset_status <= 8'h00;
      system_reset <= 1'b0;
    end else begin
      reset_status <= masked_sources;
      system_reset <= |masked_sources;
    end
  end
endmodule