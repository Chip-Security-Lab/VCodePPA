module or_gate_2input_8bit_generate (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] y
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : or_loop
            assign y[i] = a[i] | b[i];
        end
    endgenerate
endmodule
