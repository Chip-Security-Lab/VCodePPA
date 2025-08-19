module xor2_8 #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : xor_gen
            assign Y[i] = A[i] ^ B[i]; // 按位异或
        end
    endgenerate
endmodule
