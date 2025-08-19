module serializer_reset #(parameter WIDTH = 8)(
  input clk, rst_n, load,
  input [WIDTH-1:0] parallel_in,
  output serial_out
);
  reg [WIDTH-1:0] shift_reg;
  reg [$clog2(WIDTH)-1:0] bit_counter;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= 0;
      bit_counter <= 0;
    end else if (load) begin
      shift_reg <= parallel_in;
      bit_counter <= 0;
    end else if (bit_counter < WIDTH)
      bit_counter <= bit_counter + 1;
  end
  assign serial_out = shift_reg[WIDTH-1-bit_counter];
endmodule
