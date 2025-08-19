module not_gate_4bit (
    input wire [3:0] A,
    output wire [3:0] Y
);
    assign Y = ~A;
endmodule