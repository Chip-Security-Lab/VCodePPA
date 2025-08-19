module not_gate_error (
    input wire A,
    output wire Y
);
    assign Y = (A === 1'bz) ? 1'bz : ~A;
endmodule
