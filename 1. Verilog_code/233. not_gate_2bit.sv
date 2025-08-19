module not_gate_2bit (
    input wire [1:0] A,
    output wire [1:0] Y
);
    assign Y = ~A;
endmodule
