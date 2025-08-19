module barrel_shifter #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [2:0] shift,
    output [WIDTH-1:0] result
);
assign result = (data << shift) | (data >> (WIDTH - shift));
endmodule
