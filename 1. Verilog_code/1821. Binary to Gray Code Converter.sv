module bin2gray_converter #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    // Gray code conversion: G[i] = B[i] XOR B[i+1]
    assign gray_out[WIDTH-1] = bin_in[WIDTH-1];
    genvar i;
    generate
        for (i = WIDTH-2; i >= 0; i = i - 1) begin
            assign gray_out[i] = bin_in[i] ^ bin_in[i+1];
        end
    endgenerate
endmodule