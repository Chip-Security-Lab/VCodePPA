module bit_reverser #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    genvar k;
    generate
        for (k = 0; k < WIDTH; k = k + 1) begin: rev
            assign data_out[k] = data_in[WIDTH-1-k];
        end
    endgenerate
endmodule