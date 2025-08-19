module data_selector_reset #(parameter WIDTH = 8)(
  input clk, rst_n,
  input [WIDTH-1:0] data_a, data_b, data_c, data_d,
  input [1:0] select,
  output reg [WIDTH-1:0] data_out
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      data_out <= {WIDTH{1'b0}};
    else
      case (select)
        2'b00: data_out <= data_a;
        2'b01: data_out <= data_b;
        2'b10: data_out <= data_c;
        2'b11: data_out <= data_d;
      endcase
  end
endmodule