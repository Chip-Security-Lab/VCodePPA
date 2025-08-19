module dual_clock_reset_sync (
  input wire clk_a,
  input wire clk_b,
  input wire reset_in,
  output wire reset_a,
  output wire reset_b
);
  reg [2:0] sync_a;
  reg [2:0] sync_b;
  
  always @(posedge clk_a or posedge reset_in) begin
    if (reset_in)
      sync_a <= 3'b111;
    else
      sync_a <= {sync_a[1:0], 1'b0};
  end
  
  always @(posedge clk_b or posedge reset_in) begin
    if (reset_in)
      sync_b <= 3'b111;
    else
      sync_b <= {sync_b[1:0], 1'b0};
  end
  
  assign reset_a = sync_a[2];
  assign reset_b = sync_b[2];
endmodule