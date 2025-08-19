//SystemVerilog
module serializer_reset #(parameter WIDTH = 8)(
  input clk, rst_n, load,
  input [WIDTH-1:0] parallel_in,
  output serial_out
);
  reg [WIDTH-1:0] shift_reg;
  reg [$clog2(WIDTH)-1:0] bit_counter;
  wire valid_bit;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= {WIDTH{1'b0}};
      bit_counter <= {$clog2(WIDTH){1'b0}};
    end else if (load) begin
      shift_reg <= parallel_in;
      bit_counter <= {$clog2(WIDTH){1'b0}};
    end else if (bit_counter != WIDTH-1) begin
      bit_counter <= bit_counter + 1'b1;
    end
  end
  
  // Use bit masking for serial output selection
  assign valid_bit = (bit_counter < WIDTH);
  assign serial_out = valid_bit ? shift_reg[WIDTH-1-bit_counter] : 1'b0;
endmodule