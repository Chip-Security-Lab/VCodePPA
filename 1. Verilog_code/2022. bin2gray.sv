module bin2gray #(parameter WIDTH=4) (
    input [WIDTH-1:0] bin_in,
    output [WIDTH-1:0] gray_out
);
    assign gray_out = bin_in ^ (bin_in >> 1);
endmodule