module endian_converter #(
    parameter WIDTH = 32,
    parameter BYTE_WIDTH = 8
)(
    input [WIDTH-1:0] big_endian_in,
    output [WIDTH-1:0] little_endian_out
);
    genvar byte_idx;
    generate
        for (byte_idx = 0; byte_idx < WIDTH/BYTE_WIDTH; byte_idx = byte_idx + 1) begin: swap
            assign little_endian_out[byte_idx*BYTE_WIDTH +: BYTE_WIDTH] = 
                big_endian_in[(WIDTH/BYTE_WIDTH-1-byte_idx)*BYTE_WIDTH +: BYTE_WIDTH];
        end
    endgenerate
endmodule
