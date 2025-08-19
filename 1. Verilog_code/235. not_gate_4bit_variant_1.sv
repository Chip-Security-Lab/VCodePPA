//SystemVerilog
module not_gate_1bit (
    input wire A,
    output wire Y
);
    assign Y = ~A;
endmodule

module not_gate_4bit (
    input wire [3:0] A,
    output wire [3:0] Y
);
    not_gate_1bit not0 (.A(A[0]), .Y(Y[0]));
    not_gate_1bit not1 (.A(A[1]), .Y(Y[1]));
    not_gate_1bit not2 (.A(A[2]), .Y(Y[2]));
    not_gate_1bit not3 (.A(A[3]), .Y(Y[3]));
endmodule