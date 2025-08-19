module reset_sync_ring(
  input  wire clk,
  input  wire rst_n,
  output wire out_rst
);
  reg [3:0] ring_reg;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      ring_reg <= 4'b1000;
    else
      ring_reg <= {ring_reg[2:0], ring_reg[3]};
  end
  assign out_rst = ring_reg[0];
endmodule

