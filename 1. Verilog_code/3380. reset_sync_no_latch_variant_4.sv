//SystemVerilog
module reset_sync_no_latch(
  input  wire clk,
  input  wire rst_n,
  output reg  synced
);
  // Using two-stage reset synchronizer
  reg [1:0] sync_stages;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sync_stages <= 2'b00;
      synced      <= 1'b0;
    end else begin
      sync_stages <= {sync_stages[0], 1'b1};
      synced      <= sync_stages[1];
    end
  end
endmodule