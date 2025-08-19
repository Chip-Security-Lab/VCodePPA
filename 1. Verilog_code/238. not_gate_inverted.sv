module not_gate_inverted (
    input wire A,
    output wire Y
);
    assign Y = ~A;
endmodule