module not_gate_controlled #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] A,
    input wire control,
    output wire [WIDTH-1:0] Y
);
    assign Y = control ? ~A : A;
endmodule
