module dynamic_scale #(W=24)(input [W-1:0] in, input [4:0] shift, output [W-1:0] out);
assign out = shift[4] ? in << -shift : in >> shift;
endmodule