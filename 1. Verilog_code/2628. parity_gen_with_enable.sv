module parity_gen_with_enable(
  input clk, enable,
  input [15:0] data_word,
  output reg parity_result
);
  always @(posedge clk) begin
    if (enable)
      parity_result <= ^data_word;
  end
endmodule