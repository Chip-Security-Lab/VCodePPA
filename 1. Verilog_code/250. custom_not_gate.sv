module custom_not_gate (
    input wire in,
    output wire out
);
    assign out = ~in;
endmodule