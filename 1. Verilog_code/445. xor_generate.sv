module xor_generate(input [3:0] a, b, output [3:0] y);
    genvar i;
    generate
        for(i=0; i<4; i=i+1) begin
            assign y[i] = a[i] ^ b[i];
        end
    endgenerate
endmodule