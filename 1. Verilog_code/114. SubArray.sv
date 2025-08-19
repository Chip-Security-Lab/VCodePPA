module SubArray(input [3:0] a, b, output [3:0] d);
    genvar i;
    generate
        for(i=0; i<4; i=i+1) 
            assign d[i] = a[i] - b[i];
    endgenerate
endmodule