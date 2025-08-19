module bit_interleaver #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_a, data_b,
    output [2*WIDTH-1:0] interleaved_data
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: interleave
            assign interleaved_data[2*i] = data_a[i];
            assign interleaved_data[2*i+1] = data_b[i];
        end
    endgenerate
endmodule