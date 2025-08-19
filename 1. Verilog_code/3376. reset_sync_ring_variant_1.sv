//SystemVerilog
module reset_sync_ring(
  input  wire clk,
  input  wire rst_n,
  output wire out_rst
);
  reg [3:0] ring_reg;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      ring_reg <= 4'b0001;  // Modified reset value to match functionality after retiming
    else
      ring_reg <= {ring_reg[0], ring_reg[3:1]};  // Retimed shift direction
  end
  
  assign out_rst = ring_reg[3];  // Adjusted output tap position
endmodule