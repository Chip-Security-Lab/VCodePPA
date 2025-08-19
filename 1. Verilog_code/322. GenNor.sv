module GenNor #(parameter N=8)(input [N-1:0] a, b, output [N-1:0] y);
    generate
        genvar i;
        for(i=0; i<N; i=i+1) begin : NOR_ARRAY
            assign y[i] = ~(a[i] | b[i]);
        end
    endgenerate
endmodule