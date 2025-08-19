module not_gate_6bit (
    input wire [5:0] A,
    output wire [5:0] Y
);
    assign Y = ~A;
endmodule