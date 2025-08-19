//SystemVerilog
module reset_sync_basic(
  input  wire clk,
  input  wire async_rst_n,
  output reg  sync_rst_n
);
  (* keep = "true" *) reg [2:0] rst_shift;
  
  always @(posedge clk or negedge async_rst_n) begin
    if(!async_rst_n) begin
      rst_shift <= 3'b000;
      sync_rst_n <= 1'b0;
    end else begin
      rst_shift <= {rst_shift[1:0], 1'b1};
      sync_rst_n <= rst_shift[2];
    end
  end
endmodule