module shift_register_reset #(parameter WIDTH = 16)(
  input clk, reset, shift_en, data_in,
  output reg [WIDTH-1:0] shift_data
);
  always @(posedge clk) begin
    if (reset)
      shift_data <= {WIDTH{1'b0}};
    else if (shift_en)
      shift_data <= {shift_data[WIDTH-2:0], data_in};
  end
endmodule