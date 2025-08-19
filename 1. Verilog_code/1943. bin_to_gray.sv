module bin_to_gray #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    // 格雷码转换：gray_out[i] = bin_in[i] ^ bin_in[i+1]
    genvar i;
    generate
        for (i = 0; i < WIDTH-1; i = i + 1) begin: gray_conv
            assign gray_out[i] = bin_in[i] ^ bin_in[i+1];
        end
    endgenerate
    assign gray_out[WIDTH-1] = bin_in[WIDTH-1];
endmodule