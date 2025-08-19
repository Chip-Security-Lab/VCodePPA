module not_gate_8bit (
    input wire [7:0] A,
    output wire [7:0] Y
);
    assign Y = ~A;
endmodule