module or_gate_conditional (
    input wire a,
    input wire b,
    input wire sel,
    output wire y
);
    assign y = (sel) ? (a | b) : 0;
endmodule
