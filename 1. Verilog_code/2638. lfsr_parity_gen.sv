module lfsr_parity_gen(
  input clk, rst,
  input [7:0] data_in,
  output reg parity
);
  reg [3:0] lfsr;
  
  always @(posedge clk) begin
    if (rst) begin
      lfsr <= 4'b1111;
      parity <= 1'b0;
    end else begin
      lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
      parity <= (^data_in) ^ lfsr[0];
    end
  end
endmodule