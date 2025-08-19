module xor_recursive(input [7:0] a, b, output [7:0] y);
    assign y[0] = a[0] ^ b[0];
    genvar i;
    generate
        for(i=1; i<8; i=i+1) begin
            assign y[i] = a[i] ^ b[i] ^ y[i-1];
        end
    endgenerate
endmodule