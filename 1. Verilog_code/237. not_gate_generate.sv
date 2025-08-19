module not_gate_generate (
    input wire [3:0] A,
    output wire [3:0] Y
);
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : not_gen
            assign Y[i] = ~A[i];
        end
    endgenerate
endmodule