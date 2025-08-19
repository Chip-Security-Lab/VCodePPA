//SystemVerilog
module param_odd_parity_reg #(
  parameter DATA_W = 32
)(
  input clk,
  input [DATA_W-1:0] data,
  output reg parity_bit
);
  always @(posedge clk) begin
    integer i;
    reg [1:0] parity_count;
    parity_count = 2'b00;
    i = 0;
    
    while (i < DATA_W) begin
      parity_count = parity_count + data[i];
      i = i + 1;
    end
    
    parity_bit <= (parity_count[0] ^ parity_count[1]);
  end
endmodule