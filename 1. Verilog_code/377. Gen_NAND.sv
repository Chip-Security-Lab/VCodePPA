module Gen_NAND(
    input [15:0] vec_a, vec_b,
    output [15:0] result
);
    genvar i;
    generate
        for(i=0; i<16; i=i+1) begin : BIT_NAND
            assign result[i] = ~(vec_a[i] & vec_b[i]);
        end
    endgenerate
endmodule

