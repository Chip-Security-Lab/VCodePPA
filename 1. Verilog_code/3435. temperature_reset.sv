module temperature_reset #(
  parameter HOT_THRESHOLD = 8'hC0
) (
  input wire clk,
  input wire [7:0] temperature,
  input wire rst_n,
  output reg temp_reset
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      temp_reset <= 1'b0;
    else
      temp_reset <= (temperature > HOT_THRESHOLD);
  end
endmodule