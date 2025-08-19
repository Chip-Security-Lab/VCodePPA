module not_gate_enable (
    input wire A,
    input wire enable,
    output wire Y
);
    assign Y = enable ? ~A : 1'bz;
endmodule
