//SystemVerilog
module sync_even_parity(
  input clk,
  input rst, 
  input [15:0] data,
  output reg parity
);

  reg [15:0] data_reg;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      data_reg <= 16'b0;
      parity <= 1'b0;
    end else begin
      data_reg <= data;
      parity <= ^data_reg;
    end
  end

endmodule