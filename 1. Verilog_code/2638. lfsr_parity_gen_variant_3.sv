//SystemVerilog
module lfsr_parity_gen(
  input clk,
  input rst,
  input valid,
  output reg ready,
  input [7:0] data_in,
  output reg parity
);
  reg [3:0] lfsr;
  reg data_valid;

  always @(posedge clk) begin
    if (rst) begin
      lfsr <= 4'b1111;
      parity <= 1'b0;
      ready <= 1'b1;
      data_valid <= 1'b0;
    end else begin
      if (valid && ready) begin
        // Optimize LFSR update and parity calculation
        lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
        parity <= (^data_in) ^ lfsr[0]; // Maintain parity calculation
        data_valid <= 1'b1;
      end
      ready <= ~data_valid; // Maintain ready signal logic
    end
  end
endmodule