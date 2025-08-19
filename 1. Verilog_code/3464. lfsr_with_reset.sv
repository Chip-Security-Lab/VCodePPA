module lfsr_with_reset #(parameter WIDTH = 8)(
  input clk, async_rst, enable,
  output reg [WIDTH-1:0] lfsr_out
);
  wire feedback = lfsr_out[7] ^ lfsr_out[3] ^ lfsr_out[2] ^ lfsr_out[1];
  always @(posedge clk or posedge async_rst) begin
    if (async_rst)
      lfsr_out <= 8'h01;  // Non-zero seed
    else if (enable)
      lfsr_out <= {lfsr_out[WIDTH-2:0], feedback};
  end
endmodule