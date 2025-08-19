module serial_parity_calc(
  input clk, rst, bit_in, start,
  output reg parity_done,
  output reg parity_bit
);
  reg [3:0] bit_count;
  
  always @(posedge clk) begin
    if (rst || start) begin
      parity_bit <= 1'b0;
      bit_count <= 4'd0;
      parity_done <= 1'b0;
    end else if (bit_count < 4'd8) begin
      parity_bit <= parity_bit ^ bit_in;
      bit_count <= bit_count + 1'b1;
      parity_done <= (bit_count == 4'd7);
    end
  end
endmodule