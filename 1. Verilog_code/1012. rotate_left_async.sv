module rotate_left_async #(parameter WIDTH=8) (
    input [WIDTH-1:0] din,
    input [$clog2(WIDTH)-1:0] shift,
    output [WIDTH-1:0] dout
);
assign dout = (din << shift) | (din >> (WIDTH - shift));
endmodule