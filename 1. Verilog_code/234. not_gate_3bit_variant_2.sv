//SystemVerilog
module not_gate_1bit (
    input wire A,
    output wire Y
);
    assign Y = ~A;
endmodule

module not_gate_3bit (
    input wire [2:0] A,
    output wire [2:0] Y
);
    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : not_instances
            not_gate_1bit not_inst (
                .A(A[i]),
                .Y(Y[i])
            );
        end
    endgenerate
endmodule