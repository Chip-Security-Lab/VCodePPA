module not_gate_10bit (
    input wire [9:0] A,
    output wire [9:0] Y
);
    assign Y = ~A;
endmodule
