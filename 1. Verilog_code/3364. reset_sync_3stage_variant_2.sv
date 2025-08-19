//SystemVerilog
module reset_sync_3stage(
  input  wire clk,
  input  wire rst_n,
  output wire synced_rst
);
  // Reset synchronization registers
  (* dont_touch = "true" *) (* async_reg = "true" *)
  reg [2:0] rst_sync_ff;
  
  // Efficient 3-stage synchronization with optimized attributes
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rst_sync_ff <= 3'b000;
    end else begin
      rst_sync_ff <= {rst_sync_ff[1:0], 1'b1};
    end
  end
  
  // Use continuous assignment for output to reduce logic
  assign synced_rst = rst_sync_ff[2];
  
endmodule