module RD4 #(parameter WIDTH=4)(
  input [WIDTH-1:0] in_data,
  input rst,
  output [WIDTH-1:0] out_data
);
assign out_data = rst ? {WIDTH{1'b0}} : in_data;
endmodule
