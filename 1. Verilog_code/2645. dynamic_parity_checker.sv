module dynamic_parity_checker #(
    parameter MAX_WIDTH = 64
)(
    input [$clog2(MAX_WIDTH)-1:0] width,
    input [MAX_WIDTH-1:0] data,
    output parity
);
genvar i;
wire [MAX_WIDTH:0] xor_chain;
assign xor_chain[0] = 0;
generate
    for (i=0; i<MAX_WIDTH; i=i+1) begin : gen_xor
        assign xor_chain[i+1] = (i < width) ? 
            xor_chain[i] ^ data[i] : xor_chain[i];
    end
endgenerate
assign parity = xor_chain[MAX_WIDTH];
endmodule