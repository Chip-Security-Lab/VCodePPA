module Gen_XNOR(
    input [15:0] vec1, vec2,
    output [15:0] result
);
    genvar i;
    generate
        for(i=0; i<16; i=i+1) begin : BIT_XNOR
            assign result[i] = ~(vec1[i] ^ vec2[i]);
        end
    endgenerate
endmodule
