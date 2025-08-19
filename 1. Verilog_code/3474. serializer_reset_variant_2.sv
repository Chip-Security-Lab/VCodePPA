//SystemVerilog
module serializer_reset #(parameter WIDTH = 8)(
  input clk, rst_n, load,
  input [WIDTH-1:0] parallel_in,
  output reg serial_out
);
  reg [WIDTH-1:0] shift_reg;
  reg [$clog2(WIDTH)-1:0] bit_counter;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= {WIDTH{1'b0}};
      bit_counter <= {$clog2(WIDTH){1'b0}};
      serial_out <= 1'b0;
    end else if (load) begin
      shift_reg <= parallel_in;
      bit_counter <= {$clog2(WIDTH){1'b0}};
      serial_out <= parallel_in[WIDTH-1];
    end else if (bit_counter < WIDTH-1) begin
      bit_counter <= bit_counter + 1'b1;
      serial_out <= shift_reg[WIDTH-2-bit_counter];
    end
  end
endmodule