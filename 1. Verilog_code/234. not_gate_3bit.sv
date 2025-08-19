module not_gate_3bit (
    input wire [2:0] A,
    output wire [2:0] Y
);
    assign Y = ~A;
endmodule