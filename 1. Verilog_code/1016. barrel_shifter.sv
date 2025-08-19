module barrel_shifter #(parameter N=8) (
    input [N-1:0] in,
    input [$clog2(N)-1:0] shift,
    output [N-1:0] out
);
assign out = (in << (N - shift)) | (in >> shift);
endmodule